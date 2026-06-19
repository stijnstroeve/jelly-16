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
        alu_op : out std_logic_vector(3 downto 0);
        
        status_we : out std_logic;

        mem_read : out std_logic;
        mem_write : out std_logic;
        mem_to_reg : out std_logic;

        jump : out std_logic;

        halt : out std_logic
    );
end entity decoder;

architecture rtl of decoder is

begin
    process (opcode) is
    begin
        reg_write <= '0';
        alu_src <= ALU_SRC_REG;
        mem_read <= '0';
        mem_write <= '0';
        mem_to_reg <= '0';
        jump <= '0';
        halt <= '0';
        status_we <= '0';
        alu_op <= (others => '0');

        case opcode is
            when OP_NOP =>
                null; -- Default values already mean "do nothing"

            when OP_LDI =>
                -- Write the immediate operand into the destination register
                reg_write <= '1';
                alu_src <= ALU_SRC_IMM;

            when OP_LUI =>
                -- Same as LDI, but the datapath places the immediate in the upper byte
                reg_write <= '1';
                alu_src <= ALU_SRC_IMM;

            when OP_MOV =>
                -- Copy a source register into the destination register
                reg_write <= '1';

            when OP_LOAD =>
                -- Read data memory and write the value into the register file
                reg_write <= '1';
                mem_read <= '1';
                mem_to_reg <= '1';

            when OP_STORE =>
                -- Write a register value out to data memory
                mem_write <= '1';

            when OP_JMP =>
                -- Jump to a target address
                jump <= '1';

            when OP_HALT =>
                -- Stall the processor
                halt <= '1';

            -- ALU register-register operations. The low three opcode bits select
            -- the ALU function (see jelly_pkg) and the result is written back.
            when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_XOR | OP_SHL | OP_SHR =>
                reg_write <= '1';
                alu_op <= opcode(3 downto 0);
                status_we <= '1';

            when OP_CMP =>
                -- CMP only updates the flags, the ALU result is discarded.
                alu_op <= opcode(3 downto 0);
                status_we <= '1';

            when others =>
                null; -- unknown opcode should behave like NOP
        end case;
    end process;

end architecture rtl;
