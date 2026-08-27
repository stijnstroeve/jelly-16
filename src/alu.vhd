library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.jelly_pkg.all;

entity alu is
    generic (
        DATA_WIDTH : integer := JELLY_DATA_WIDTH
    );
    port (
        a : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        b : in std_logic_vector(DATA_WIDTH - 1 downto 0);
        op : in std_logic_vector(3 downto 0);
        result : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        status : out std_logic_vector(3 downto 0)
    );
end entity alu;

architecture main of alu is
begin
    process (a, b, op) is
        -- (DATA_WIDTH + 1)-bit accumulator so it captures carry / borrow
        variable akku : unsigned(DATA_WIDTH downto 0);
        variable res : std_logic_vector(DATA_WIDTH - 1 downto 0);
        variable n, z, c, o : std_logic;

    begin
        -- ALU / Data Path
        case op is
            when OP_ADD =>
                akku := resize(unsigned(a), DATA_WIDTH + 1) + resize(unsigned(b), DATA_WIDTH + 1);
            -- CMP is the same as SUB; the datapath discards the result and keeps only the flags.
            when OP_SUB | OP_CMP =>
                akku := resize(unsigned(a), DATA_WIDTH + 1) + (not resize(unsigned(b), DATA_WIDTH + 1)) + 1;
            when OP_AND =>
                akku := resize(unsigned(a and b), DATA_WIDTH + 1);
            when OP_OR =>
                akku := resize(unsigned(a or b), DATA_WIDTH + 1);
            when OP_XOR =>
                akku := resize(unsigned(a xor b), DATA_WIDTH + 1);
            when OP_SHR =>
                akku := resize(unsigned(a), DATA_WIDTH + 1) srl 1;
            when others =>
                akku := (others => '0');
        end case;

        res := std_logic_vector(akku(DATA_WIDTH - 1 downto 0));
        result <= res;

        -- Status flags, bit order NZCO.
        n := res(DATA_WIDTH - 1); -- N
        if res = (res'range => '0') then
            z := '1';
        else
            z := '0';
        end if; -- Z
        c := akku(DATA_WIDTH); -- C

        case op is
            when OP_ADD =>
                -- Overflow if both inputs share a sign and the result flips it
                if (a(DATA_WIDTH - 1) = b(DATA_WIDTH - 1)) and (res(DATA_WIDTH - 1) /= a(DATA_WIDTH - 1)) then
                    o := '1';
                else
                    o := '0';
                end if;
            when OP_SUB | OP_CMP =>
                -- Overflow if inputs differ in sign and result takes b's sign
                if (a(DATA_WIDTH - 1) /= b(DATA_WIDTH - 1)) and (res(DATA_WIDTH - 1) /= a(DATA_WIDTH - 1)) then
                    o := '1';
                else
                    o := '0';
                end if;
            when others =>
                o := '0';
        end case;

        status <= n & z & c & o;
    end process;
end architecture main;
