library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.jelly_pkg.all;

entity status_reg is
    port (
        clk : in std_logic;
        rst : in std_logic;

        status_in : in std_logic_vector(3 downto 0);
        status_we : in std_logic;
        status_clr : in std_logic;

        status_out : out std_logic_vector(3 downto 0)
    );
end entity status_reg;

architecture rtl of status_reg is
    signal status : std_logic_vector(3 downto 0) := (others => '0');
begin
    process (clk, rst) is
    begin
        if rst = '0' then
            status <= (others => '0');
        elsif rising_edge(clk) then
            if status_clr = '1' then
                status <= (others => '0');
            elsif status_we = '1' then
                status <= status_in;
            end if;
        end if;
    end process;

    status_out <= status;

end architecture rtl;
