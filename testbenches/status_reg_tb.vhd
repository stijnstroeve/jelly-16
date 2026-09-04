library ieee;
use ieee.std_logic_1164.all;

entity status_reg_tb is
end entity status_reg_tb;

architecture sim of status_reg_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1'; -- Is active low
    signal status_in : std_logic_vector(3 downto 0) := (others => '0');
    signal status_we : std_logic := '0';
    signal status_clr : std_logic := '0';
    signal status_out : std_logic_vector(3 downto 0);

    signal sim_done : boolean := false;
begin
    dut: entity work.status_reg
    port map (
        clk => clk,
        rst => rst,
        status_in => status_in,
        status_we => status_we,
        status_clr => status_clr,
        status_out => status_out
    );

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

    stim: process

        procedure step is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure step;

        procedure check(constant expected : in std_logic_vector(3 downto 0); constant name : in string) is
        begin
            assert status_out = expected report name & ": expected " & to_string(expected) & " got " & to_string(status_out) severity error;
        end procedure check;

    begin
        -- ===== Initial value is zero =====
        wait for 1 ns;
        check("0000", "INIT");

        -- ===== Write enable stores the input =====
        status_in <= "1010";
        status_we <= '1';
        step;
        check("1010", "WRITE 1010");

        -- ===== Without write enable the value is held =====
        status_we <= '0';
        status_in <= "0101";
        step;
        check("1010", "HOLD ignores input");

        -- ===== Clear resets to zero =====
        status_clr <= '1';
        step;
        check("0000", "CLEAR");
        status_clr <= '0';

        -- ===== Clear has priority over write =====
        status_in <= "1111";
        status_we <= '1';
        status_clr <= '1';
        step;
        check("0000", "PRIORITY clear over write");
        status_clr <= '0';
        step;
        check("1111", "WRITE after clear released");

        -- ===== Reset is asynchronous and beats everything =====
        status_we <= '1';
        status_in <= "0110";
        rst <= '0';
        wait for 1 ns;
        check("0000", "RESET async");
        step;
        check("0000", "RESET held over write");
        rst <= '1';
        step;
        check("0110", "WRITE after reset released");
        status_we <= '0';

        report "Status reg testbench completed" severity note;
        sim_done <= true;
        wait;
    end process stim;

end architecture sim;
