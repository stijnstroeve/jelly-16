library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Minimal testbench, runs the given program
entity jelly_16_tb is
end entity jelly_16_tb;

architecture sim of jelly_16_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

begin
    dut: entity work.jelly_16
    generic map (
        PROG_FILE => "programs/printer/printer.hex",
        DATA_FILE => "programs/printer/printer.data.hex",
        MEM_ADDR_WIDTH => 12
    )
    port map (
        clk => clk,
        rst => rst
    );

    -- Generate a clock signal
    clk <= not clk after CLK_PERIOD / 2;

    -- Hold reset low for two cycles, then release it to start the program
    rst <= '0', '1' after 2 * CLK_PERIOD;

end architecture sim;
