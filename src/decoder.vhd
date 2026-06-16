library ieee;
use ieee.std_logic_1164.all;
use work.jelly_pkg.all;

entity decoder is
    generic (
        OPCODE_BITS : integer := JELLY_OPCODE_BITS
    );
    port (
        opcode : in std_logic_vector(OPCODE_BITS - 1 downto 0);

        reg_write : out std_logic;
        alu_src : out std_logic;
        alu_op : out std_logic_vector(2 downto 0);

        mem_read : out std_logic;
        mem_write : out std_logic;
        mem_to_reg : out std_logic;

        branch : out std_logic;
        jump : out std_logic;

        halt : out std_logic
    );
end entity decoder;

architecture rtl of decoder is

begin
    process (opcode) is
    begin
        -- Safe defaults: do nothing. Each opcode overrides only what it needs.
        reg_write <= '0';
        alu_src <= '0';
        alu_op <= "000";
        mem_read <= '0';
        mem_write <= '0';
        mem_to_reg <= '0';
        branch <= '0';
        jump <= '0';
        halt <= '0';

        case opcode is
            when OP_NOP =>
                null; -- defaults already mean "do nothing"

            when OP_LDI =>
                -- Write the immediate operand into the destination register.
                reg_write <= '1';
                alu_src <= '1';

            when OP_LUI =>
                -- Like LDI, but the datapath places the immediate in the upper byte.
                reg_write <= '1';
                alu_src <= '1';

            when OP_MOV =>
                -- Copy a source register into the destination register.
                reg_write <= '1';

            when OP_LOAD =>
                -- Read data memory and write the value into the register file.
                reg_write <= '1';
                mem_read <= '1';
                mem_to_reg <= '1';

            when OP_STORE =>
                -- Write a register value out to data memory.
                mem_write <= '1';

            when OP_JMP =>
                -- Unconditional jump: redirect the program counter.
                jump <= '1';

            when OP_HALT =>
                -- Stall the machine: drives the program counter's hold input so
                -- it stops advancing. No architectural state is changed.
                halt <= '1';

            -- ALU register-register operations. The low three opcode bits select
            -- the ALU function (see jelly_pkg) and the result is written back.
            when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR | OP_SHL | OP_SHR =>
                reg_write <= '1';
                alu_op <= opcode(2 downto 0);

            when OP_CMP =>
                -- CMP only updates the flags; the ALU result is discarded.
                alu_op <= opcode(2 downto 0);

            when others =>
                null; -- unknown opcode: behave like NOP
        end case;
    end process;

end architecture rtl;
