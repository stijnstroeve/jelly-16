library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regfile_tb is
end entity regfile_tb;

architecture sim of regfile_tb is

    constant TB_DATA_WIDTH : integer := 16;
    constant TB_ADDR_WIDTH : integer := 4;

    constant CLK_PERIOD : time := 10 ns;

    -- DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal rd_addr_a : std_logic_vector(TB_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal rd_data_a : std_logic_vector(TB_DATA_WIDTH - 1 downto 0);
    signal rd_addr_b : std_logic_vector(TB_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal rd_data_b : std_logic_vector(TB_DATA_WIDTH - 1 downto 0);
    signal rd_addr_c : std_logic_vector(TB_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal rd_data_c : std_logic_vector(TB_DATA_WIDTH - 1 downto 0);
    signal wr_en : std_logic := '0';
    signal wr_addr : std_logic_vector(TB_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal wr_data : std_logic_vector(TB_DATA_WIDTH - 1 downto 0) := (others => '0');

    signal sim_done : boolean := false;
begin

    -- Device under test
    dut: entity work.regfile
    generic map (
        DATA_WIDTH => TB_DATA_WIDTH,
        ADDR_WIDTH => TB_ADDR_WIDTH
    )
    port map (
        clk => clk,
        rst => rst,
        rd_addr_a => rd_addr_a,
        rd_data_a => rd_data_a,
        rd_addr_b => rd_addr_b,
        rd_data_b => rd_data_b,
        rd_addr_c => rd_addr_c,
        rd_data_c => rd_data_c,
        wr_en => wr_en,
        wr_addr => wr_addr,
        wr_data => wr_data
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

        -- Synchronous write: present address/data with wr_en high. The write
        -- commits on the rising edge, after which wr_en is cleared again.
        procedure write_reg(constant addr : in integer; constant value : in std_logic_vector(TB_DATA_WIDTH - 1 downto 0)) is
        begin
            wr_addr <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
            wr_data <= value;
            wr_en <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            wr_en <= '0';
        end procedure write_reg;

        -- Asynchronous read on port A: drive the address and, after the
        -- combinational read settles, compare rd_data_a against expected.
        procedure check_read_a(constant addr : in integer; constant expected : in std_logic_vector(TB_DATA_WIDTH - 1 downto 0); constant name : in string) is
        begin
            rd_addr_a <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
            wait for 1 ns;
            assert rd_data_a = expected report name & " (port A): expected 0x" & to_hstring(unsigned(expected)) & " got 0x" & to_hstring(unsigned(rd_data_a))
                severity error;
        end procedure check_read_a;

        -- Asynchronous read on port B.
        procedure check_read_b(constant addr : in integer; constant expected : in std_logic_vector(TB_DATA_WIDTH - 1 downto 0); constant name : in string) is
        begin
            rd_addr_b <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
            wait for 1 ns;
            assert rd_data_b = expected report name & " (port B): expected 0x" & to_hstring(unsigned(expected)) & " got 0x" & to_hstring(unsigned(rd_data_b))
                severity error;
        end procedure check_read_b;

        -- Asynchronous read on port B.
        procedure check_read_c(constant addr : in integer; constant expected : in std_logic_vector(TB_DATA_WIDTH - 1 downto 0); constant name : in string) is
        begin
            rd_addr_c <= std_logic_vector(to_unsigned(addr, TB_ADDR_WIDTH));
            wait for 1 ns;
            assert rd_data_b = expected report name & " (port C): expected 0x" & to_hstring(unsigned(expected)) & " got 0x" & to_hstring(unsigned(rd_data_b))
                severity error;
        end procedure check_read_c;

    begin
        -- Let the first clock edge pass before driving stimulus.
        wait until rising_edge(clk);

        -- ===== All registers start cleared =====
        check_read_a(0, x"0000", "INIT addr 0");
        check_read_a(7, x"0000", "INIT addr 7");
        check_read_a(15, x"0000", "INIT addr 15");

        -- ===== Write then read back =====
        write_reg(1, x"BEEF");
        check_read_a(1, x"BEEF", "WRITE/READ addr 1 = 0xBEEF");

        write_reg(10, x"1234");
        check_read_a(10, x"1234", "WRITE/READ addr 10 = 0x1234");

        write_reg(14, x"DAFD");
        check_read_a(14, x"DAFD", "WRITE/READ addr 14 = 0xDAFD");

        -- Highest and lowest addressable registers.
        write_reg(0, x"CAFE");
        check_read_a(0, x"CAFE", "WRITE/READ addr 0 = 0xCAFE");
        write_reg(15, x"FFFF");
        check_read_a(15, x"FFFF", "WRITE/READ addr 15 = 0xFFFF");

        -- ===== Overwrite leaves other registers untouched =====
        write_reg(1, x"0BAD");
        check_read_a(1, x"0BAD", "OVERWRITE addr 1 = 0x0BAD");
        check_read_a(10, x"1234", "addr 10 unchanged after addr 1 overwrite");

        -- ===== Both read ports are independent =====
        -- Port A, port B and port C can present different addresses at the same time.
        rd_addr_a <= std_logic_vector(to_unsigned(1, TB_ADDR_WIDTH));
        rd_addr_b <= std_logic_vector(to_unsigned(10, TB_ADDR_WIDTH));
        rd_addr_c <= std_logic_vector(to_unsigned(14, TB_ADDR_WIDTH));
        wait for 1 ns;
        assert rd_data_a = x"0BAD" report "DUAL-PORT: port A expected 0x0BAD got 0x" & to_hstring(unsigned(rd_data_a)) severity error;
        assert rd_data_b = x"1234" report "DUAL-PORT: port B expected 0x1234 got 0x" & to_hstring(unsigned(rd_data_b)) severity error;
        assert rd_data_c = x"DAFD" report "DUAL-PORT: port B expected 0xDAFD got 0x" & to_hstring(unsigned(rd_data_b)) severity error;

        -- Both ports pointing at the same register read the same value.
        check_read_b(0, x"CAFE", "DUAL-PORT same addr 0");
        check_read_c(0, x"CAFE", "DUAL-PORT same addr 0");

        -- ===== wr_en = '0' must not modify a register =====
        wr_addr <= std_logic_vector(to_unsigned(10, TB_ADDR_WIDTH));
        wr_data <= x"DEAD";
        wr_en <= '0';
        wait until rising_edge(clk);
        wait for 1 ns;
        check_read_a(10, x"1234", "NO-WRITE addr 10 still 0x1234");

        -- ===== Synchronous reset clears every register =====
        rst <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        rst <= '0';
        check_read_a(0, x"0000", "RESET addr 0 cleared");
        check_read_a(1, x"0000", "RESET addr 1 cleared");
        check_read_a(10, x"0000", "RESET addr 10 cleared");
        check_read_a(15, x"0000", "RESET addr 15 cleared");

        -- ===== Reads are combinational: new value appears after the edge =====
        -- The write to addr 5 commits on the rising edge; because reads are
        -- asynchronous, rd_data_a reflects the new value immediately after.
        rd_addr_a <= std_logic_vector(to_unsigned(5, TB_ADDR_WIDTH));
        wr_addr <= std_logic_vector(to_unsigned(5, TB_ADDR_WIDTH));
        wr_data <= x"5A5A";
        wr_en <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        wr_en <= '0';
        assert rd_data_a = x"5A5A" report "ASYNC-READ: addr 5 expected 0x5A5A after write edge, got 0x" & to_hstring(unsigned(rd_data_a)) severity error;

        report "Regfile testbench completed" severity note;
        sim_done <= true;
        wait;
    end process stim;

end architecture sim;
