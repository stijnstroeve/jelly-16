LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity sram is
	generic (
		INIT_FILE : string := "fib_memory.hex";
		DATA_WIDTH : integer := 16;
		ADDR_WIDTH : integer := 16
	);
	port (
		-- The memory location to read/write
		address	: in std_logic_vector(ADDR_WIDTH-1 downto 0);
		
		-- The data to write to the memory location specified by address
		data : in std_logic_vector(DATA_WIDTH-1 downto 0);

		-- Read enable
		rden : in std_logic := '1';
		
		-- Write enable
		wren : in std_logic;

		-- Clock signal, all reads/writes happen on the rising edge of clk
		clk	: in std_logic;

		-- The data read from the memory location specified by address
		q : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end sram;

architecture behav of sram is

	type ram_t is array (0 to 2**ADDR_WIDTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

	impure function load_hex(fname : string) return ram_t is
		file f      : text;
		variable l  : line;
		variable b  : std_logic_vector(DATA_WIDTH-1 downto 0);
		variable m  : ram_t := (others => (others => '0'));
		variable i  : integer := 0;
	begin
		file_open(f, fname, read_mode);

		while not endfile(f) and i <= 2**ADDR_WIDTH-1 loop
			readline(f, l);
			if l'length > 0 then
				hread(l, b);
				m(i) := b;
				i := i + 1;
			end if;
		end loop;

		file_close(f);
		return m;
	end function;

	signal ram : ram_t := load_hex(INIT_FILE);

begin
	process(clk)
	begin
		if rising_edge(clk) then
			if wren = '1' then
				ram(to_integer(unsigned(address))) <= data;
				report "RAM write: addr=" & integer'image(to_integer(unsigned(address)))
					& " data=" & integer'image(to_integer(unsigned(data)));
			end if;
			if rden = '1' then
				q <= ram(to_integer(unsigned(address)));
			end if;
		end if;
	end process;
end behav;
