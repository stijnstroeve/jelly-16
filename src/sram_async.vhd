library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity sram_async is
    generic (
        INIT_FILE : string := "";
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 8
    );
    port (
        clk : in std_logic;

        -- The memory location to read/write
        address : in std_logic_vector(ADDR_WIDTH - 1 downto 0);

        -- The data to write to the memory location specified by address
        data : in std_logic_vector(DATA_WIDTH - 1 downto 0);

        -- Write enable
        wren : in std_logic;

        -- The data read from the memory location specified by address
        q : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity sram_async;

architecture behav of sram_async is

    type ram_t is array (0 to 2 ** ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);

    impure function load_hex (fname : string) return ram_t is
        file f : text;
        variable status : file_open_status;
        variable l : line;
        variable w : std_logic_vector(DATA_WIDTH - 1 downto 0);
        variable m : ram_t := (others => (others => '0'));
        variable i : integer := 0;
    begin
        if fname = "" then
            return m;
        end if;

        file_open(status, f, fname, read_mode);
        if status /= open_ok then
            return m; -- no readable file: start from all zeros
        end if;

        while not endfile(f) and i <= 2 ** ADDR_WIDTH - 1 loop
            readline(f, l);
            if l'length > 0 then
                hread(l, w);
                m(i) := w;
                i := i + 1;
            end if;
        end loop;

        file_close(f);
        return m;
    end function load_hex;

    signal ram : ram_t := load_hex(INIT_FILE);

begin

    -- Asynchronous read
    q <= ram(to_integer(unsigned(address)));

    -- Synchronous write
    process (clk) is
    begin
        if rising_edge(clk) then
            if wren = '1' then
                ram(to_integer(unsigned(address))) <= data;
            end if;
        end if;
    end process;

end architecture behav;
