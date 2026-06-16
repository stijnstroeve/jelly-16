LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY regfile_tb IS
END regfile_tb;

ARCHITECTURE sim OF regfile_tb IS

	CONSTANT TB_DATA_WIDTH : integer := 16;
	CONSTANT TB_ADDR_WIDTH : integer := 4;

	CONSTANT CLK_PERIOD : time := 10 ns;

	-- DUT signals
	SIGNAL clk       : std_logic := '0';
	SIGNAL rst       : std_logic := '0';
	SIGNAL rd_addr_a : std_logic_vector(TB_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL rd_data_a : std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0);
	SIGNAL rd_addr_b : std_logic_vector(TB_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL rd_data_b : std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0);
	SIGNAL wr_en     : std_logic := '0';
	SIGNAL wr_addr   : std_logic_vector(TB_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL wr_data   : std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0) := (others => '0');

	SIGNAL sim_done : boolean := false;
BEGIN

	-- Device under test
	dut : ENTITY work.regfile
		GENERIC MAP (
			DATA_WIDTH => TB_DATA_WIDTH,
			ADDR_WIDTH => TB_ADDR_WIDTH
		)
		PORT MAP (
			clk       => clk,
			rst       => rst,
			rd_addr_a => rd_addr_a,
			rd_data_a => rd_data_a,
			rd_addr_b => rd_addr_b,
			rd_data_b => rd_data_b,
			wr_en     => wr_en,
			wr_addr   => wr_addr,
			wr_data   => wr_data
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

		-- Synchronous write: present address/data with wr_en high. The write
		-- commits on the rising edge, after which wr_en is cleared again.
		PROCEDURE write_reg(
			CONSTANT addr  : IN integer;
			CONSTANT value : IN std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0)
		) IS
		BEGIN
			wr_addr <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
			wr_data <= value;
			wr_en   <= '1';
			WAIT UNTIL rising_edge(clk);
			WAIT FOR 1 ns;
			wr_en   <= '0';
		END PROCEDURE;

		-- Asynchronous read on port A: drive the address and, after the
		-- combinational read settles, compare rd_data_a against expected.
		PROCEDURE check_read_a(
			CONSTANT addr     : IN integer;
			CONSTANT expected : IN std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0);
			CONSTANT name     : IN string
		) IS
		BEGIN
			rd_addr_a <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
			WAIT FOR 1 ns;
			ASSERT rd_data_a = expected
				REPORT name & " (port A): expected 0x" &
				       to_hstring(unsigned(expected)) & " got 0x" &
				       to_hstring(unsigned(rd_data_a))
				SEVERITY error;
		END PROCEDURE;

		-- Asynchronous read on port B.
		PROCEDURE check_read_b(
			CONSTANT addr     : IN integer;
			CONSTANT expected : IN std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0);
			CONSTANT name     : IN string
		) IS
		BEGIN
			rd_addr_b <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
			WAIT FOR 1 ns;
			ASSERT rd_data_b = expected
				REPORT name & " (port B): expected 0x" &
				       to_hstring(unsigned(expected)) & " got 0x" &
				       to_hstring(unsigned(rd_data_b))
				SEVERITY error;
		END PROCEDURE;

	BEGIN
		-- Let the first clock edge pass before driving stimulus.
		WAIT UNTIL rising_edge(clk);

		-- ===== All registers start cleared =====
		check_read_a(0,  x"0000", "INIT addr 0");
		check_read_a(7,  x"0000", "INIT addr 7");
		check_read_a(15, x"0000", "INIT addr 15");

		-- ===== Write then read back =====
		write_reg(1, x"BEEF");
		check_read_a(1, x"BEEF", "WRITE/READ addr 1 = 0xBEEF");

		write_reg(10, x"1234");
		check_read_a(10, x"1234", "WRITE/READ addr 10 = 0x1234");

		-- Highest and lowest addressable registers.
		write_reg(0,  x"CAFE");
		check_read_a(0,  x"CAFE", "WRITE/READ addr 0 = 0xCAFE");
		write_reg(15, x"FFFF");
		check_read_a(15, x"FFFF", "WRITE/READ addr 15 = 0xFFFF");

		-- ===== Overwrite leaves other registers untouched =====
		write_reg(1, x"0BAD");
		check_read_a(1,  x"0BAD", "OVERWRITE addr 1 = 0x0BAD");
		check_read_a(10, x"1234", "addr 10 unchanged after addr 1 overwrite");

		-- ===== Both read ports are independent =====
		-- Port A and port B can present different addresses at the same time.
		rd_addr_a <= std_logic_vector(to_unsigned(1, TB_ADDR_WIDTH));
		rd_addr_b <= std_logic_vector(to_unsigned(10, TB_ADDR_WIDTH));
		WAIT FOR 1 ns;
		ASSERT rd_data_a = x"0BAD"
			REPORT "DUAL-PORT: port A expected 0x0BAD got 0x" &
			       to_hstring(unsigned(rd_data_a))
			SEVERITY error;
		ASSERT rd_data_b = x"1234"
			REPORT "DUAL-PORT: port B expected 0x1234 got 0x" &
			       to_hstring(unsigned(rd_data_b))
			SEVERITY error;

		-- Both ports pointing at the same register read the same value.
		check_read_b(0, x"CAFE", "DUAL-PORT same addr 0");

		-- ===== wr_en = '0' must not modify a register =====
		wr_addr <= std_logic_vector(to_unsigned(10, TB_ADDR_WIDTH));
		wr_data <= x"DEAD";
		wr_en   <= '0';
		WAIT UNTIL rising_edge(clk);
		WAIT FOR 1 ns;
		check_read_a(10, x"1234", "NO-WRITE addr 10 still 0x1234");

		-- ===== Synchronous reset clears every register =====
		rst <= '1';
		WAIT UNTIL rising_edge(clk);
		WAIT FOR 1 ns;
		rst <= '0';
		check_read_a(0,  x"0000", "RESET addr 0 cleared");
		check_read_a(1,  x"0000", "RESET addr 1 cleared");
		check_read_a(10, x"0000", "RESET addr 10 cleared");
		check_read_a(15, x"0000", "RESET addr 15 cleared");

		-- ===== Reads are combinational: new value appears after the edge =====
		-- The write to addr 5 commits on the rising edge; because reads are
		-- asynchronous, rd_data_a reflects the new value immediately after.
		rd_addr_a <= std_logic_vector(to_unsigned(5, TB_ADDR_WIDTH));
		wr_addr   <= std_logic_vector(to_unsigned(5, TB_ADDR_WIDTH));
		wr_data   <= x"5A5A";
		wr_en     <= '1';
		WAIT UNTIL rising_edge(clk);
		WAIT FOR 1 ns;
		wr_en     <= '0';
		ASSERT rd_data_a = x"5A5A"
			REPORT "ASYNC-READ: addr 5 expected 0x5A5A after write edge, got 0x" &
			       to_hstring(unsigned(rd_data_a))
			SEVERITY error;

		REPORT "Regfile testbench completed" SEVERITY note;
		sim_done <= true;
		WAIT;
	END PROCESS;

END sim;
