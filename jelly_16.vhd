LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

LIBRARY work;

ENTITY jelly_16 IS
	PORT(
        clk : IN std_logic;
        rst : IN std_logic;
        data_in : IN std_logic_vector(15 DOWNTO 0);
	);
END jelly_16;

ARCHITECTURE main OF jelly_16 IS

BEGIN

END main;