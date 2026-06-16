LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY sram_tb IS
END sram_tb;

ARCHITECTURE sim OF sram_tb IS

	-- Keep the array small so simulation stays fast. The init file
	-- data/tb_data.hex holds 8 words (0x0000 .. 0x0007); the remaining
	-- words (8 .. 15) are zero-filled by the load_hex function.
	CONSTANT TB_DATA_WIDTH : integer := 16;
	CONSTANT TB_ADDR_WIDTH : integer := 4;

	CONSTANT CLK_PERIOD : time := 10 ns;

	-- DUT signals
	SIGNAL clk     : std_logic := '0';
	SIGNAL address : std_logic_vector(TB_ADDR_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL data    : std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0) := (others => '0');
	SIGNAL rden    : std_logic := '0';
	SIGNAL wren    : std_logic := '0';
	SIGNAL q       : std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0);

	SIGNAL sim_done : boolean := false;
BEGIN

	-- Device under test
	dut : ENTITY work.sram
		GENERIC MAP (
			INIT_FILE  => "data/tb_data.hex",
			DATA_WIDTH => TB_DATA_WIDTH,
			ADDR_WIDTH => TB_ADDR_WIDTH
		)
		PORT MAP (
			address => address,
			clk     => clk,
			data    => data,
			rden    => rden,
			wren    => wren,
			q       => q
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

		-- Synchronous read: present the address with rden high (and wren
		-- low), wait for the edge that registers q, then compare.
		PROCEDURE check_read(
			CONSTANT addr     : IN integer;
			CONSTANT expected : IN std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0);
			CONSTANT name     : IN string
		) IS
		BEGIN
			address <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
			rden    <= '1';
			wren    <= '0';
			WAIT UNTIL rising_edge(clk);
			-- Allow the registered output to settle after the edge.
			WAIT FOR 1 ns;
			ASSERT q = expected
				REPORT name & ": expected 0x" &
				       to_hstring(unsigned(expected)) & " got 0x" &
				       to_hstring(unsigned(q))
				SEVERITY error;
		END PROCEDURE;

		-- Synchronous write: present address/data with wren high. The write
		-- commits on the rising edge. rden is held low so q is not disturbed.
		PROCEDURE write_mem(
			CONSTANT addr  : IN integer;
			CONSTANT value : IN std_logic_vector(TB_DATA_WIDTH-1 DOWNTO 0)
		) IS
		BEGIN
			address <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
			data    <= value;
			wren    <= '1';
			rden    <= '0';
			WAIT UNTIL rising_edge(clk);
			WAIT FOR 1 ns;
			wren    <= '0';
		END PROCEDURE;

	BEGIN
		-- Let the first clock edge pass before driving stimulus.
		WAIT UNTIL rising_edge(clk);

		-- ===== Read back the values loaded from the hex file =====
		check_read(0, x"0000", "INIT addr 0");
		check_read(1, x"0001", "INIT addr 1");
		check_read(2, x"0002", "INIT addr 2");
		check_read(7, x"0007", "INIT addr 7");
		
		-- Words beyond the file contents are zero-filled.
		check_read(8,  x"0000", "INIT addr 8 (zero-filled)");
		check_read(15, x"0000", "INIT addr 15 (zero-filled)");

		-- ===== Write then read back =====
		write_mem(3, x"BEEF");
		check_read(3, x"BEEF", "WRITE/READ addr 3 = 0xBEEF");

		write_mem(10, x"1234");
		check_read(10, x"1234", "WRITE/READ addr 10 = 0x1234");

		-- Overwrite an existing location
		write_mem(3, x"CAFE");
		check_read(3, x"CAFE", "OVERWRITE addr 3 = 0xCAFE");

		-- A previously written address is unaffected by writes elsewhere.
		check_read(10, x"1234", "addr 10 unchanged after addr 3 overwrite");

		-- ===== wren = '0' must not modify memory =====
		address <= std_logic_vector(to_unsigned(5, TB_ADDR_WIDTH));
		data    <= x"DEAD";
		wren    <= '0';
		rden    <= '0';
		WAIT UNTIL rising_edge(clk);
		WAIT FOR 1 ns;
		check_read(5, x"0005", "NO-WRITE addr 5 still 0x0005");

		-- ===== rden = '0' must hold q stable =====
		-- First load q with a known value from addr 1.
		check_read(1, x"0001", "prep: q = 0x0001 from addr 1");
		-- Now point at a different address with rden low; q must not update.
		address <= std_logic_vector(to_unsigned(2, TB_ADDR_WIDTH));
		rden    <= '0';
		wren    <= '0';
		WAIT UNTIL rising_edge(clk);
		WAIT FOR 1 ns;
		ASSERT q = x"0001"
			REPORT "RDEN-LOW: q changed while read disabled, got 0x" &
			       to_hstring(unsigned(q))
			SEVERITY error;

		-- ===== Simultaneous read+write to the same address =====
		-- Single-port RAM: on the same edge q captures the OLD contents
		-- while the new value is being written. Seed addr 6 first.
		write_mem(6, x"AAAA");
		address <= std_logic_vector(to_unsigned(6, TB_ADDR_WIDTH));
		data    <= x"5555";
		wren    <= '1';
		rden    <= '1';
		WAIT UNTIL rising_edge(clk);
		WAIT FOR 1 ns;
		ASSERT q = x"AAAA"
			REPORT "R+W same addr: expected OLD value 0xAAAA on q, got 0x" &
			       to_hstring(unsigned(q))
			SEVERITY error;
		wren <= '0';
		-- The write still took effect; a following read sees the new value.
		check_read(6, x"5555", "R+W same addr: new value 0x5555 on next read");

		REPORT "SRAM testbench completed" SEVERITY note;
		sim_done <= true;
		WAIT;
	END PROCESS;

END sim;
