LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE sim OF alu_tb IS

	-- Opcodes (must match alu.vhd)
	CONSTANT OP_ADD : std_logic_vector(3 DOWNTO 0) := "1000";
	CONSTANT OP_SUB : std_logic_vector(3 DOWNTO 0) := "1001";
	CONSTANT OP_AND : std_logic_vector(3 DOWNTO 0) := "1010";
	CONSTANT OP_OR : std_logic_vector(3 DOWNTO 0) := "1011";
	CONSTANT OP_XOR : std_logic_vector(3 DOWNTO 0) := "1100";
	CONSTANT OP_SHL : std_logic_vector(3 DOWNTO 0) := "1101";
	CONSTANT OP_SHR : std_logic_vector(3 DOWNTO 0) := "1110";
	CONSTANT OP_CMP : std_logic_vector(3 DOWNTO 0) := "1111";

	CONSTANT CLK_PERIOD : time := 10 ns;

	-- DUT signals
	SIGNAL clk    : std_logic := '0';
	SIGNAL rst    : std_logic := '0';
	SIGNAL a      : std_logic_vector(15 DOWNTO 0) := (others => '0');
	SIGNAL b      : std_logic_vector(15 DOWNTO 0) := (others => '0');
	SIGNAL op     : std_logic_vector(3 DOWNTO 0)  := (others => '0');
	SIGNAL result : std_logic_vector(15 DOWNTO 0);
	SIGNAL status : std_logic_vector(3 DOWNTO 0);

	SIGNAL sim_done : boolean := false;
BEGIN

	-- Device under test
	dut : ENTITY work.alu
		PORT MAP (
			clk    => clk,
			rst    => rst,
			a      => a,
			b      => b,
			op     => op,
			result => result,
			status => status
		);

	-- Clock generation
	clk_gen : PROCESS
	BEGIN
		WHILE NOT sim_done LOOP
			clk <= '0';
			WAIT FOR CLK_PERIOD / 2;
			clk <= '1';
			WAIT FOR CLK_PERIOD / 2;
		END LOOP;
		WAIT;
	END PROCESS;

	-- Stimulus and checking
	stim : PROCESS

		-- Drive a + b through the ALU and check the registered result.
		-- The result is captured on the rising edge, so apply inputs,
		-- wait one clock, then compare.
		PROCEDURE check_op(
			CONSTANT opcode   : IN std_logic_vector(3 DOWNTO 0);
			CONSTANT in_a     : IN std_logic_vector(15 DOWNTO 0);
			CONSTANT in_b     : IN std_logic_vector(15 DOWNTO 0);
			CONSTANT expected : IN std_logic_vector(15 DOWNTO 0);
			CONSTANT exp_status : IN std_logic_vector(3 DOWNTO 0);
			CONSTANT name     : IN string
		) IS
		BEGIN
			a  <= in_a;
			b  <= in_b;
			op <= opcode;
			WAIT UNTIL rising_edge(clk);
			-- Allow the registered output to settle after the edge.
			WAIT FOR 1 ns;
			ASSERT result = expected
				REPORT name & ": expected 0x" &
				       to_hstring(unsigned(expected)) & " got 0x" &
				       to_hstring(unsigned(result))
				SEVERITY error;
			-- Status flags, bit order NZCO.
			ASSERT status = exp_status
				REPORT name & ": status (NZCO) expected " &
				       to_string(exp_status) & " got " & to_string(status)
				SEVERITY error;
		END PROCEDURE;

	BEGIN
		-- Apply reset (active low) for a couple of cycles.
		rst <= '0';
		WAIT FOR 2 * CLK_PERIOD;
		WAIT UNTIL rising_edge(clk);
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

		REPORT "ALU testbench completed" SEVERITY note;
		sim_done <= true;
		WAIT;
	END PROCESS;

END sim;
