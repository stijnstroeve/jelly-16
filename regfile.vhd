
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity regfile is
    generic (
        DATA_WIDTH : integer := 16;
        ADDR_WIDTH : integer := 4
    );
    port (
        clk : in  std_logic;
        rst : in  std_logic;
 
        -- read port A
        rd_addr_a : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        rd_data_a : out std_logic_vector(DATA_WIDTH-1 downto 0);
 
        -- read port B
        rd_addr_b : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        rd_data_b : out std_logic_vector(DATA_WIDTH-1 downto 0);
 
        -- write port
        wr_en    : in  std_logic;                                   -- 1 = write enabled
        wr_addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        wr_data  : in  std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity regfile;
 
architecture rtl of regfile is
 
    -- register array is 2**ADDR_WIDTH registers of DATA_WIDTH bits
    type reg_array_t is array (0 to (2**ADDR_WIDTH)-1)
        of std_logic_vector(DATA_WIDTH-1 downto 0);

    -- initialize all registers to 0
    signal regs : reg_array_t := (others => (others => '0'));
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                regs <= (others => (others => '0'));
            elsif wr_en = '1' then
                regs(to_integer(unsigned(wr_addr))) <= wr_data;
            end if;
        end if;
    end process;

    -- Write is synchronous, but reads are asynchronous
    rd_data_a <= regs(to_integer(unsigned(rd_addr_a)));
    rd_data_b <= regs(to_integer(unsigned(rd_addr_b)));
 
end architecture rtl;