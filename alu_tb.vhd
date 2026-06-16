LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY alu_tb IS
END alu_tb;

ARCHITECTURE sim OF alu_tb IS

	-- Opcodes (must match alu.vhd)
	CONSTANT OP_ADD : std_logic_vector(3 DOWNTO 0) := "1000";
	CONSTANT OP_SUB : std_logic_vector(3 DOWNTO 0) := "1001";

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

	-- Compute the expected status flags for a given operation.
	-- Bit order is NZCO: status(3)=N, status(2)=Z, status(1)=C, status(0)=O.
	--   N = result MSB (negative, two's complement)
	--   Z = result is zero
	--   C = carry-out of the 17-bit addition.
	--       SUB is computed as a + (~b) + 1, so C = 1 means no borrow (a >= b).
	--   O = signed (two's complement) overflow
	FUNCTION expected_status(
		opcode : std_logic_vector(3 DOWNTO 0);
		in_a   : std_logic_vector(15 DOWNTO 0);
		in_b   : std_logic_vector(15 DOWNTO 0)
	) RETURN std_logic_vector IS
		VARIABLE ext : unsigned(16 DOWNTO 0);
		VARIABLE res : std_logic_vector(15 DOWNTO 0);
		VARIABLE n, z, c, o : std_logic;
	BEGIN
		CASE opcode IS
			WHEN OP_ADD =>
				ext := resize(unsigned(in_a), 17) + resize(unsigned(in_b), 17);
			WHEN OP_SUB =>
				-- a - b via a + (~b) + 1; carry-out means a >= b (no borrow)
				ext := resize(unsigned(in_a), 17)
				     + resize(unsigned(NOT in_b), 17)
				     + 1;
			WHEN OTHERS =>
				ext := (OTHERS => '0');
		END CASE;

		res := std_logic_vector(ext(15 DOWNTO 0));

		n := res(15);
		IF res = x"0000" THEN z := '1'; ELSE z := '0'; END IF;
		c := ext(16);

		CASE opcode IS
			WHEN OP_ADD =>
				-- overflow if both inputs share a sign and the result flips it
				IF (in_a(15) = in_b(15)) AND (res(15) /= in_a(15)) THEN
					o := '1';
				ELSE
					o := '0';
				END IF;
			WHEN OP_SUB =>
				-- overflow if inputs differ in sign and result takes b's sign
				IF (in_a(15) /= in_b(15)) AND (res(15) /= in_a(15)) THEN
					o := '1';
				ELSE
					o := '0';
				END IF;
			WHEN OTHERS =>
				o := '0';
		END CASE;

		RETURN n & z & c & o;
	END FUNCTION;

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
			CONSTANT name     : IN string
		) IS
			VARIABLE exp_status : std_logic_vector(3 DOWNTO 0);
		BEGIN
			exp_status := expected_status(opcode, in_a, in_b);
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
		check_op(OP_ADD, x"0001", x"0001", x"0002", "ADD 1+1");
		check_op(OP_ADD, x"0000", x"0000", x"0000", "ADD 0+0");
		check_op(OP_ADD, x"00FF", x"0001", x"0100", "ADD 255+1");
		check_op(OP_ADD, x"1234", x"4321", x"5555", "ADD 0x1234+0x4321");
		check_op(OP_ADD, x"FFFF", x"0001", x"0000", "ADD overflow FFFF+1");

		-- ===== Subtraction =====
		check_op(OP_SUB, x"0002", x"0001", x"0001", "SUB 2-1");
		check_op(OP_SUB, x"0000", x"0000", x"0000", "SUB 0-0");
		check_op(OP_SUB, x"0100", x"0001", x"00FF", "SUB 256-1");
		check_op(OP_SUB, x"5555", x"1234", x"4321", "SUB 0x5555-0x1234");
		check_op(OP_SUB, x"0000", x"0001", x"FFFF", "SUB underflow 0-1");

		REPORT "ALU testbench completed" SEVERITY note;
		sim_done <= true;
		WAIT;
	END PROCESS;

END sim;
