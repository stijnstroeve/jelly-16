library ieee;
use ieee.std_logic_1164.all;
 
package jelly_pkg is
 
    constant JELLY_DATA_WIDTH : integer := 16;
    constant JELLY_ADDR_WIDTH : integer := 16;
    constant JELLY_REG_BITS   : integer := 4;
    constant JELLY_OPCODE_BITS: integer := 4;

    -- Instruction opcodes
    constant OP_NOP : std_logic_vector(3 downto 0) := "0000";
    constant OP_LDI : std_logic_vector(3 downto 0) := "0001";
    constant OP_LUI : std_logic_vector(3 downto 0) := "0010";
    constant OP_MOV : std_logic_vector(3 downto 0) := "0011";
    constant OP_LOAD : std_logic_vector(3 downto 0) := "0100";
    constant OP_STORE : std_logic_vector(3 downto 0) := "0101";

    -- Control flow operations
    constant OP_JMP : std_logic_vector(3 downto 0) := "0110";
    constant OP_HALT : std_logic_vector(3 downto 0) := "0111";
 
    -- ALU operations
    constant OP_ADD : std_logic_vector(3 downto 0) := "1000";
    constant OP_SUB : std_logic_vector(3 downto 0) := "1001";
    constant OP_AND : std_logic_vector(3 downto 0) := "1010";
    constant OP_OR : std_logic_vector(3 downto 0) := "1011";
    constant OP_XOR : std_logic_vector(3 downto 0) := "1100";
    constant OP_SHL : std_logic_vector(3 downto 0) := "1101";
    constant OP_SHR : std_logic_vector(3 downto 0) := "1110";
    constant OP_CMP : std_logic_vector(3 downto 0) := "1111";

    -- CMP condition codes
    constant COND_ALWAYS : std_logic_vector(3 downto 0) := "0000";
    constant COND_EQ : std_logic_vector(3 downto 0) := "0001";
    constant COND_NEQ : std_logic_vector(3 downto 0) := "0010";
    constant COND_NEG : std_logic_vector(3 downto 0) := "0011";
    constant COND_POS : std_logic_vector(3 downto 0) := "0100";
    constant COND_CS : std_logic_vector(3 downto 0) := "0101";
    constant COND_CC : std_logic_vector(3 downto 0) := "0110";
    constant COND_VS : std_logic_vector(3 downto 0) := "0111";
    constant COND_VC : std_logic_vector(3 downto 0) := "1000";

    -- ALU source selection
    constant ALU_SRC_REG : std_logic := '0';
    constant ALU_SRC_IMM : std_logic := '1';

end package jelly_pkg;