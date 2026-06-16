library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity pc is
    generic (
        ADDR_WIDTH : integer := 16
    );
    port (
        clk : in std_logic;
        rst : in std_logic; -- synchronous reset to 0
        stall : in std_logic; -- 1 = hold current address
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
            if rst = '1' then
                pc_reg <= (others => '0');
            elsif stall = '1' then
                pc_reg <= pc_reg; -- hold
            elsif branch = '1' then
                pc_reg <= unsigned(branch_target); -- jump / taken branch
            else
                pc_reg <= pc_reg + 1; -- sequential fetch (word-addressed)
            end if;
        end if;
    end process;

    pc_out <= std_logic_vector(pc_reg);

end architecture rtl;
