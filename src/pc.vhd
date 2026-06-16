library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.jelly_pkg.all;

entity pc is
    generic (
        ADDR_WIDTH : integer := JELLY_ADDR_WIDTH
    );
    port (
        clk : in std_logic;
        rst : in std_logic;

        hold : in std_logic; -- 1 = hold current address

        branch : in std_logic; -- 1 = load branch_target
        branch_target : in std_logic_vector(ADDR_WIDTH - 1 downto 0); -- target for taken branch/jump

        pc_out : out std_logic_vector(ADDR_WIDTH - 1 downto 0) -- current instruction address
    );
end entity pc;

architecture rtl of pc is
    signal pc_reg : unsigned(ADDR_WIDTH - 1 downto 0) := (others => '0');
begin
    process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '0' then
                pc_reg <= (others => '0');
            elsif hold = '1' then
                pc_reg <= pc_reg; -- hold current address
            elsif branch = '1' then
                pc_reg <= unsigned(branch_target); -- load branch target
            else
                pc_reg <= pc_reg + 1; -- increment to next instruction
            end if;
        end if;
    end process;

    pc_out <= std_logic_vector(pc_reg);

end architecture rtl;
