#!/usr/bin/env python3
import argparse
import re
import sys

DATA_WIDTH = 16
WORD_MASK = (1 << DATA_WIDTH) - 1

OP = {
    "NOP": 0x0, "LDI": 0x1, "LUI": 0x2, "MOV": 0x3,
    "LOAD": 0x4, "STORE": 0x5, "JMP": 0x6, "HALT": 0x7,
    "ADD": 0x8, "SUB": 0x9, "AND": 0xA, "OR": 0xB,
    "XOR": 0xC, "ADDI": 0xD, "SHR": 0xE, "CMP": 0xF,
}
ALU_RRR = {"ADD", "SUB", "AND", "OR", "XOR"}
ALU_SHIFT = {"SHR"}
COND = {
    "ALWAYS": 0x0, "AL": 0x0,
    "EQ": 0x1, "Z": 0x1,
    "NEQ": 0x2, "NE": 0x2, "NZ": 0x2,
    "NEG": 0x3, "MI": 0x3, "N": 0x3,
    "POS": 0x4, "PL": 0x4,
    "CS": 0x5, "C": 0x5, "HS": 0x5,
    "CC": 0x6, "NC": 0x6, "LO": 0x6,
    "VS": 0x7, "V": 0x7, "OV": 0x7,
    "VC": 0x8, "NV": 0x8,
}

class AssemblyError(Exception):
    def __init__(self, line_numb, message):
        super().__init__(message)
        self.line_numb = line_numb
        self.msg = message

def parse_int(tok, line_numb, symbols=None):
    """Parse a numeric value into an integer"""
    t = tok.strip()
    if symbols is not None and t.upper() in symbols:
        return symbols[t.upper()]
    
    neg = False
    if t.startswith(("+", "-")):
        neg = t[0] == "-"
        t = t[1:]

    try:
        if t.lower().startswith("0x"):
            val = int(t, 16)
        elif t.lower().startswith("0b"):
            val = int(t, 2)
        else:
            val = int(t, 10)
    except ValueError:
        raise AssemblyError(line_numb, f"expected a number or known symbol, got '{tok}'")
    return -val if neg else val


def parse_reg(tok, line_numb):
    """Parse register names r0 to r15 into a 4-bit register number"""
    m = re.fullmatch(r"[rR](\d+)", tok.strip())
    if not m:
        raise AssemblyError(line_numb, f"expected register r0..r15, got '{tok}'")
    n = int(m.group(1))
    if not 0 <= n <= 15:
        raise AssemblyError(line_numb, f"register out of range r0..r15: '{tok}'")
    return n


def parse_mem(tok, line_numb):
    """Parse a memory operand [rs] into a register number. Just for convenience."""
    t = tok.strip()
    if t.startswith("[") and t.endswith("]"):
        t = t[1:-1]
    return parse_reg(t, line_numb)


def split_operands(rest):
    if not rest.strip():
        return []
    return [p.strip() for p in rest.split(",") if p.strip() != ""]


def need(ops, n, mnem, line_numb):
    if len(ops) != n:
        raise AssemblyError(
            line_numb, f"{mnem} expects {n} operand(s), got {len(ops)}: {ops}"
        )


def encode(mnem, ops, line_numb, symbols):
    """Encode one instruction into a 16-bit word."""
    op = OP[mnem]

    if mnem in ("NOP", "HALT"):
        need(ops, 0, mnem, line_numb)
        return op << 12

    if mnem in ("LDI", "LUI", "ADDI"):
        need(ops, 2, mnem, line_numb)
        rd = parse_reg(ops[0], line_numb)
        imm = parse_int(ops[1], line_numb, symbols)
        if not -128 <= imm <= 255:
            raise AssemblyError(line_numb, f"immediate {imm} does not fit in 8 bits (-128..255)")
        imm &= 0xFF
        return (op << 12) | (rd << 8) | imm

    if mnem == "MOV":
        need(ops, 2, mnem, line_numb)
        rd = parse_reg(ops[0], line_numb)
        rs = parse_reg(ops[1], line_numb)
        return (op << 12) | (rd << 8) | (rs << 4)

    # LOAD rd, [rs]
    if mnem == "LOAD":
        need(ops, 2, mnem, line_numb)
        rd = parse_reg(ops[0], line_numb)
        rs = parse_mem(ops[1], line_numb)
        return (op << 12) | (rd << 8) | (rs << 4)

    # STORE [rs], rt
    if mnem == "STORE":
        need(ops, 2, mnem, line_numb)
        rs = parse_mem(ops[0], line_numb)
        rt = parse_reg(ops[1], line_numb)
        return (op << 12) | (rs << 4) | rt

    # JMP rs  |  JMP cond, rs
    if mnem == "JMP":
        if len(ops) == 1:
            cond, rs = COND["ALWAYS"], parse_reg(ops[0], line_numb)
        elif len(ops) == 2:
            key = ops[0].strip().upper()
            if key not in COND:
                raise AssemblyError(line_numb, f"unknown condition code '{ops[0]}'")
            cond, rs = COND[key], parse_reg(ops[1], line_numb)
        else:
            raise AssemblyError(line_numb, f"JMP expects `rs` or `cond, rs`, got {ops}")
        return (op << 12) | (cond << 8) | (rs << 4)

    # ADD rd, rs, rt
    if mnem in ALU_RRR:
        need(ops, 3, mnem, line_numb)
        rd = parse_reg(ops[0], line_numb)
        rs = parse_reg(ops[1], line_numb)
        rt = parse_reg(ops[2], line_numb)
        return (op << 12) | (rd << 8) | (rs << 4) | rt

    # SHL rd, rs  (hardware shifts by 1, ignores rt)
    if mnem in ALU_SHIFT:
        need(ops, 2, mnem, line_numb)
        rd = parse_reg(ops[0], line_numb)
        rs = parse_reg(ops[1], line_numb)
        return (op << 12) | (rd << 8) | (rs << 4)

    # CMP rs, rt
    if mnem == "CMP":
        need(ops, 2, mnem, line_numb)
        rs = parse_reg(ops[0], line_numb)
        rt = parse_reg(ops[1], line_numb)
        return (op << 12) | (rs << 4) | rt

    raise AssemblyError(line_numb, f"unknown mnemonic '{mnem}'")


def assemble(text):
    current_section = "text"
    sections = {}

    raw_lines = text.splitlines()


    def initialize_section(section_name):
        sections[section_name] = {
            "symbols": {},
            "items": [],
            "addr": 0,
            "words": [],
        }

    initialize_section(current_section)

    def add_symbol(name, value, line_numb):
        key = name.upper()
        if key in sections[current_section]["symbols"]:
            raise AssemblyError(line_numb, f"symbol '{name}' redefined")
        if key in OP or key in COND:
            raise AssemblyError(line_numb, f"'{name}' is a reserved word")
        sections[current_section]["symbols"][key] = value

    for line_numb, raw in enumerate(raw_lines, start=1):
        section = sections[current_section]

        """Remove comments starting with ; or #"""
        line = raw
        for i, ch in enumerate(line):
            if ch in ";#":
                line = line[:i]
        line = line.strip()

        if not line:
            continue

        # Leading labels: one or more name: tokens.
        while True:
            m = re.match(r"^([A-Za-z_.$][\w.$]*)\s*:\s*(.*)$", line)
            if not m:
                break
            add_symbol(m.group(1), section["addr"], line_numb)
            line = m.group(2).strip()
        if not line:
            continue

        parts = line.split(None, 1)
        head = parts[0]
        rest = parts[1] if len(parts) > 1 else ""

        # . Directive handling
        if head.lower() == ".org":
            target = parse_int(rest, line_numb, section["symbols"])
            if target < section["addr"]:
                raise AssemblyError(line_numb, f".org {target} is before current address {section['addr']}")
            for _ in range(target - section["addr"]):
                section["items"].append((section["addr"], "word", 0, line_numb))
                section["addr"] += 1
            continue

        if head.lower() == ".word":
            for field in split_operands(rest):
                section["items"].append((section["addr"], "word", field, line_numb))
                section["addr"] += 1
            continue

        if head.lower() == ".equ":
            args = split_operands(rest) if "," in rest else rest.split(None, 1)
            if len(args) != 2:
                raise AssemblyError(line_numb, ".equ expects: .equ NAME, VALUE")
            add_symbol(args[0].strip(), parse_int(args[1], line_numb, section["symbols"]), line_numb)
            continue

        if head.lower() == ".data":
            current_section = "data"
            if current_section not in sections:
                initialize_section(current_section)
            continue

        if head.lower() == ".text":
            current_section = "text"
            continue

        # Instruction
        mnem = head.upper()
        if mnem not in OP:
            raise AssemblyError(line_numb, f"unknown mnemonic or directive '{head}'")
        section["items"].append((section["addr"], "instr", (mnem, split_operands(rest)), line_numb))
        section["addr"] += 1

    # Resolve symbols and encode
    for section_name, section in sections.items():
        symbols = section["symbols"]
        items = section["items"]
        addr = section["addr"]
        out = [0] * addr
        for at, kind, payload, line_numb in items:
            if kind == "instr":
                mnem, ops = payload
                out[at] = encode(mnem, ops, line_numb, symbols)
            else:
                val = payload if isinstance(payload, int) else parse_int(payload, line_numb, symbols)
                if not -32768 <= val <= 65535:
                    raise AssemblyError(line_numb, f".word value {val} does not fit in 16 bits")
                out[at] = val & WORD_MASK
        sections[section_name]["words"] = out

    return sections


def main(argv=None):
    ap = argparse.ArgumentParser(description="Assembler for the jelly_16 CPU architecture")
    ap.add_argument("input", help="source .asm file")
    ap.add_argument("-o", "--output", help="output .hex file (default: input with .hex extension)")
    args = ap.parse_args(argv)

    with open(args.input, "r") as f:
        text = f.read()

    try:
        sections = assemble(text)
    except AssemblyError as e:
        print(f"{args.input}:{e.line_numb}: error: {e.msg}", file=sys.stderr)
        return 1

    base_path = out_path = args.output or re.sub(r"\.[^.]*$", "", args.input)
    for section_name, section in sections.items():
        lines = "".join(f"{w:04X}\n" for w in section["words"])

        if section_name != "text":
            out_path = f"{base_path}.{section_name}.hex"
        else:
            out_path = f"{base_path}.hex"

        with open(out_path, "w") as f:
            f.write(lines)
        print(f"wrote {len(section['words'])} word(s) to {out_path}", file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())
