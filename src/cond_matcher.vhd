library ieee;
use ieee.std_logic_1164.all;
use work.jelly_pkg.all;

entity cond_matcher is
    port (
        cond_code : in std_logic_vector(3 downto 0);
        status : in std_logic_vector(3 downto 0);
        cond_met : out std_logic
    );
end entity cond_matcher;

architecture rtl of cond_matcher is

begin
    process (cond_code, status) is
    begin
        case cond_code is
            when COND_ALWAYS => cond_met <= '1';
            when COND_EQ => cond_met <= '1' when status(2) = '1' else '0'; -- Z
            when COND_NEQ => cond_met <= '1' when status(2) = '0' else '0'; -- Z
            when COND_NEG => cond_met <= '1' when status(3) = '1' else '0'; -- N
            when COND_POS => cond_met <= '1' when status(3) = '0' else '0'; -- N
            when COND_CS => cond_met <= '1' when status(0) = '1' else '0'; -- C
            when COND_CC => cond_met <= '1' when status(0) = '0' else '0'; -- C
            when COND_VS => cond_met <= '1' when status(1) = '1' else '0'; -- V
            when COND_VC => cond_met <= '1' when status(1) = '0' else '0'; -- V

            when others =>
                cond_met <= '0';
        end case;
    end process;

end architecture rtl;
