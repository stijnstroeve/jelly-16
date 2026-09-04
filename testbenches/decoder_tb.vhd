library ieee;
use ieee.std_logic_1164.all;
use work.jelly_pkg.all;

entity decoder_tb is
end entity decoder_tb;

architecture sim of decoder_tb is
    signal opcode : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_write : std_logic;
    signal alu_a_src : std_logic_vector(1 downto 0);
    signal alu_b_src : std_logic_vector(1 downto 0);
    signal alu_op : std_logic_vector(3 downto 0);
    signal reg_a_src : std_logic_vector(1 downto 0);
    signal reg_b_src : std_logic_vector(1 downto 0);
    signal status_we : std_logic;
    signal mem_read : std_logic;
    signal mem_write : std_logic;
    signal mem_to_reg : std_logic;
    signal jump : std_logic;
    signal halt : std_logic;
begin
    dut: entity work.decoder
    port map (
        opcode => opcode,
        reg_write => reg_write,
        alu_a_src => alu_a_src,
        alu_b_src => alu_b_src,
        alu_op => alu_op,
        reg_a_src => reg_a_src,
        reg_b_src => reg_b_src,
        status_we => status_we,
        mem_read => mem_read,
        mem_write => mem_write,
        mem_to_reg => mem_to_reg,
        jump => jump,
        halt => halt
    );

    stim: process
        procedure check(
            constant op : in std_logic_vector(3 downto 0);
            constant ctrl : in std_logic_vector(6 downto 0);
            constant exp_alu_op : in std_logic_vector(3 downto 0);
            constant name : in string
        )
        is
            variable got : std_logic_vector(6 downto 0);
        begin
            opcode <= op;
            wait for 1 ns;
            got := reg_write & status_we & mem_read & mem_write & mem_to_reg & jump & halt;
            assert got = ctrl report name & ": control expected " & to_string(ctrl) & " got " & to_string(got) severity error;
            assert alu_op = exp_alu_op report name & ": alu_op expected " & to_string(exp_alu_op) & " got " & to_string(alu_op) severity error;
        end procedure check;

        procedure check_src(
            constant exp_alu_a : in std_logic_vector(1 downto 0);
            constant exp_alu_b : in std_logic_vector(1 downto 0);
            constant exp_reg_a : in std_logic_vector(1 downto 0);
            constant exp_reg_b : in std_logic_vector(1 downto 0);
            constant name : in string
        )
        is
        begin
            assert alu_a_src = exp_alu_a report name & ": alu_a_src expected " & to_string(exp_alu_a) & " got " & to_string(alu_a_src) severity error;
            assert alu_b_src = exp_alu_b report name & ": alu_b_src expected " & to_string(exp_alu_b) & " got " & to_string(alu_b_src) severity error;
            assert reg_a_src = exp_reg_a report name & ": reg_a_src expected " & to_string(exp_reg_a) & " got " & to_string(reg_a_src) severity error;
            assert reg_b_src = exp_reg_b report name & ": reg_b_src expected " & to_string(exp_reg_b) & " got " & to_string(reg_b_src) severity error;
        end procedure check_src;

    begin
        check(OP_NOP, "0000000", "0000", "NOP");
        check_src(ALU_A_SRC_REG_A, ALU_B_SRC_REG_B, REG_A_SRC_RS, REG_B_SRC_RT, "NOP");

        check(OP_LDI, "1000000", "0000", "LDI");
        check_src(ALU_A_SRC_REG_A, ALU_B_SRC_IMM, REG_A_SRC_RS, REG_B_SRC_RT, "LDI");

        check(OP_LUI, "1000000", "0000", "LUI");
        check_src(ALU_A_SRC_REG_A, ALU_B_SRC_IMM, REG_A_SRC_RS, REG_B_SRC_RT, "LUI");

        check(OP_MOV, "1000000", "0000", "MOV");
        check_src(ALU_A_SRC_REG_A, ALU_B_SRC_REG_B, REG_A_SRC_RS, REG_B_SRC_RT, "MOV");

        check(OP_LOAD, "1010100", "0000", "LOAD");
        check(OP_STORE, "0001000", "0000", "STORE");
        check(OP_JMP, "0000010", "0000", "JMP");
        check(OP_HALT, "0000001", "0000", "HALT");

        -- ===== ALU register-register operations =====
        check(OP_ADD, "1100000", OP_ADD, "ADD");
        check_src(ALU_A_SRC_REG_A, ALU_B_SRC_REG_B, REG_A_SRC_RS, REG_B_SRC_RT, "ADD");
        check(OP_SUB, "1100000", OP_SUB, "SUB");
        check(OP_AND, "1100000", OP_AND, "AND");
        check(OP_OR, "1100000", OP_OR, "OR");
        check(OP_XOR, "1100000", OP_XOR, "XOR");
        check(OP_SHR, "1100000", OP_SHR, "SHR");

        -- ===== ADDI adds the immediate to the destination register =====
        check(OP_ADDI, "1100000", OP_ADD, "ADDI");
        check_src(ALU_A_SRC_REG_A, ALU_B_SRC_IMM, REG_A_SRC_RD, REG_B_SRC_RT, "ADDI");

        -- ===== CMP only updates the flags =====
        check(OP_CMP, "0100000", OP_CMP, "CMP");

        report "Decoder testbench completed" severity note;
        wait;
    end process stim;

end architecture sim;
