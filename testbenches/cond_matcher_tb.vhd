library ieee;
use ieee.std_logic_1164.all;
use work.jelly_pkg.all;

entity cond_matcher_tb is
end entity cond_matcher_tb;

architecture sim of cond_matcher_tb is
    signal cond_code : std_logic_vector(3 downto 0) := (others => '0');
    signal status : std_logic_vector(3 downto 0) := (others => '0');
    signal cond_met : std_logic;
begin
    dut: entity work.cond_matcher
    port map (
        cond_code => cond_code,
        status => status,
        cond_met => cond_met
    );

    stim: process
        procedure check(
            constant code : in std_logic_vector(3 downto 0);
            constant flags : in std_logic_vector(3 downto 0);
            constant expected : in std_logic;
            constant name : in string
        )
        is
        begin
            cond_code <= code;
            status <= flags;
            wait for 1 ns;
            assert cond_met = expected report name & ": expected " & std_logic'image(expected) & " got " & std_logic'image(cond_met) severity error;
        end procedure check;

    begin
        -- ===== Always =====
        check(COND_ALWAYS, "0000", '1', "ALWAYS no flags");
        check(COND_ALWAYS, "1111", '1', "ALWAYS all flags");

        -- ===== Zero flag =====
        check(COND_EQ, "0100", '1', "EQ Z=1");
        check(COND_EQ, "0000", '0', "EQ Z=0");
        check(COND_NEQ, "0000", '1', "NEQ Z=0");
        check(COND_NEQ, "0100", '0', "NEQ Z=1");

        -- ===== Negative flag =====
        check(COND_NEG, "1000", '1', "NEG N=1");
        check(COND_NEG, "0000", '0', "NEG N=0");
        check(COND_POS, "0000", '1', "POS N=0 Z=0");
        check(COND_POS, "1000", '0', "POS N=1");
        check(COND_POS, "0100", '0', "POS Z=1");

        -- ===== Carry flag =====
        check(COND_CS, "0001", '1', "CS C=1");
        check(COND_CS, "0000", '0', "CS C=0");
        check(COND_CC, "0000", '1', "CC C=0");
        check(COND_CC, "0001", '0', "CC C=1");

        -- ===== Overflow flag =====
        check(COND_VS, "0010", '1', "VS V=1");
        check(COND_VS, "0000", '0', "VS V=0");
        check(COND_VC, "0000", '1', "VC V=0");
        check(COND_VC, "0010", '0', "VC V=1");

        -- ===== Unused condition codes never match =====
        check("1001", "1111", '0', "UNUSED 1001");
        check("1111", "1111", '0', "UNUSED 1111");

        report "Cond matcher testbench completed" severity note;
        wait;
    end process stim;

end architecture sim;
