library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_tb is
end entity alu_tb;

architecture sim of alu_tb is

    -- Opcodes (must match alu.vhd)
    constant OP_ADD : std_logic_vector(3 downto 0) := "1000";
    constant OP_SUB : std_logic_vector(3 downto 0) := "1001";
    constant OP_AND : std_logic_vector(3 downto 0) := "1010";
    constant OP_OR : std_logic_vector(3 downto 0) := "1011";
    constant OP_XOR : std_logic_vector(3 downto 0) := "1100";
    constant OP_SHL : std_logic_vector(3 downto 0) := "1101";
    constant OP_SHR : std_logic_vector(3 downto 0) := "1110";
    constant OP_CMP : std_logic_vector(3 downto 0) := "1111";

    constant CLK_PERIOD : time := 10 ns;

    -- DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal a : std_logic_vector(15 downto 0) := (others => '0');
    signal b : std_logic_vector(15 downto 0) := (others => '0');
    signal op : std_logic_vector(3 downto 0) := (others => '0');
    signal result : std_logic_vector(15 downto 0);
    signal status : std_logic_vector(3 downto 0);

    signal sim_done : boolean := false;
begin

    -- Device under test
    dut: entity work.alu
    port map (
        clk => clk,
        rst => rst,
        a => a,
        b => b,
        op => op,
        result => result,
        status => status
    );

    -- Clock generation
    clk_gen: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process clk_gen;

    -- Stimulus and checking
    stim: process

        -- Drive a + b through the ALU and check the registered result.
        -- The result is captured on the rising edge, so apply inputs,
        -- wait one clock, then compare.
        procedure check_op(
            constant opcode : in std_logic_vector(3 downto 0);
            constant in_a : in std_logic_vector(15 downto 0);
            constant in_b : in std_logic_vector(15 downto 0);
            constant expected : in std_logic_vector(15 downto 0);
            constant exp_status : in std_logic_vector(3 downto 0);
            constant name : in string
        )
        is
        begin
            a <= in_a;
            b <= in_b;
            op <= opcode;
            wait until rising_edge(clk);
            -- Allow the registered output to settle after the edge.
            wait for 1 ns;
            assert result = expected report name & ": expected 0x" & to_hstring(unsigned(expected)) & " got 0x" & to_hstring(unsigned(result)) severity error;
            -- Status flags, bit order NZCO.
            assert status = exp_status report name & ": status (NZCO) expected " & to_string(exp_status) & " got " & to_string(status) severity error;
        end procedure check_op;

    begin
        -- Apply reset (active low) for a couple of cycles.
        rst <= '0';
        wait for 2 * CLK_PERIOD;
        wait until rising_edge(clk);
        rst <= '1';

        -- ===== Addition =====
        check_op(OP_ADD, x"0001", x"0001", x"0002", "0000", "ADD 1+1");
        check_op(OP_ADD, x"0000", x"0000", x"0000", "0100", "ADD 0+0");
        check_op(OP_ADD, x"00FF", x"0001", x"0100", "0000", "ADD 255+1");
        check_op(OP_ADD, x"1234", x"4321", x"5555", "0000", "ADD 0x1234+0x4321");
        check_op(OP_ADD, x"FFFF", x"0001", x"0000", "0110", "ADD overflow FFFF+1");
        check_op(OP_ADD, x"7FFF", x"0001", x"8000", "1001", "ADD overflow 0x7FFF+1");

        -- ===== Subtraction =====
        check_op(OP_SUB, x"0002", x"0001", x"0001", "0000", "SUB 2-1");
        check_op(OP_SUB, x"0000", x"0000", x"0000", "0100", "SUB 0-0");
        check_op(OP_SUB, x"0100", x"0001", x"00FF", "0000", "SUB 256-1");
        check_op(OP_SUB, x"5555", x"1234", x"4321", "0000", "SUB 0x5555-0x1234");
        check_op(OP_SUB, x"0000", x"0001", x"FFFF", "1010", "SUB underflow 0-1");
        check_op(OP_SUB, x"0002", x"0003", x"FFFF", "1010", "SUB 2-3");

        -- ===== And =====
        check_op(OP_AND, x"0000", x"0000", x"0000", "0100", "AND 0x0000 & 0x0000");
        check_op(OP_AND, x"FFFF", x"FFFF", x"FFFF", "1000", "AND 0xFFFF & 0xFFFF");
        check_op(OP_AND, x"0001", x"0001", x"0001", "0000", "AND 0x0001 & 0x0001");
        check_op(OP_AND, x"0001", x"0000", x"0000", "0100", "AND 0x0001 & 0x0000");

        -- ===== Or =====
        check_op(OP_OR, x"0000", x"0000", x"0000", "0100", "OR 0x0000 | 0x0000");
        check_op(OP_OR, x"FFFF", x"FFFF", x"FFFF", "1000", "OR 0xFFFF | 0xFFFF");
        check_op(OP_OR, x"0001", x"0001", x"0001", "0000", "OR 0x0001 | 0x0001");
        check_op(OP_OR, x"0001", x"0000", x"0001", "0000", "OR 0x0001 | 0x0000");

        -- ===== Xor =====
        check_op(OP_XOR, x"0000", x"0000", x"0000", "0100", "XOR 0x0000 ^ 0x0000");
        check_op(OP_XOR, x"FFFF", x"FFFF", x"0000", "0100", "XOR 0xFFFF ^ 0xFFFF");
        check_op(OP_XOR, x"0001", x"0001", x"0000", "0100", "XOR 0x0001 ^ 0x0001");
        check_op(OP_XOR, x"0001", x"0000", x"0001", "0000", "XOR 0x0001 ^ 0x0000");

        -- ===== Shift left =====
        check_op(OP_SHL, "0000000000000001", x"0000", "0000000000000010", "0000", "SHL 0001 << 1");
        check_op(OP_SHL, "1000000000000000", x"0000", "0000000000000000", "0110", "SHL 1000 << 1");
        check_op(OP_SHL, "0111111111111111", x"0000", "1111111111111110", "1000", "SHL 0111 << 1");

        -- ===== Shift right =====
        check_op(OP_SHR, "0000000000000010", x"0000", "0000000000000001", "0000", "SHR 0010 >> 1");
        check_op(OP_SHR, "0000000000000001", x"0000", "0000000000000000", "0100", "SHR 0001 >> 1");
        check_op(OP_SHR, "1111111111111111", x"0000", "0111111111111111", "0000", "SHR 1111 >> 1");

        -- ===== Compare =====
        check_op(OP_ADD, x"0000", x"0000", x"0000", "0100", "ADD 0+0"); -- Repeat a test to ensure output of alu is 0

        check_op(OP_CMP, x"0001", x"0001", x"0000", "0100", "CMP 1==1");
        check_op(OP_CMP, x"0010", x"0001", x"0000", "0000", "CMP 2==1");
        check_op(OP_CMP, x"0001", x"0010", x"0000", "1010", "CMP 1==2");
        check_op(OP_CMP, x"0000", x"0000", x"0000", "0100", "CMP 0==0");

        report "ALU testbench completed" severity note;
        sim_done <= true;
        wait;
    end process stim;

end architecture sim;
