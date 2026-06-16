LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

LIBRARY work;

ENTITY alu IS
	PORT(
        clk : IN std_logic;
        rst : IN std_logic;
        a : IN std_logic_vector(15 DOWNTO 0);
        b : IN std_logic_vector(15 DOWNTO 0);
        op : IN std_logic_vector(3 DOWNTO 0);
        result : OUT std_logic_vector(15 DOWNTO 0);
        status : OUT std_logic_vector(3 DOWNTO 0)
	);
END alu;

ARCHITECTURE main OF alu IS

	-- Opcodes
	CONSTANT OP_ADD : std_logic_vector(3 DOWNTO 0) := "1000";
	CONSTANT OP_SUB : std_logic_vector(3 DOWNTO 0) := "1001";
	CONSTANT OP_AND : std_logic_vector(3 DOWNTO 0) := "1010";
	CONSTANT OP_OR : std_logic_vector(3 DOWNTO 0) := "1011";
	CONSTANT OP_XOR : std_logic_vector(3 DOWNTO 0) := "1100";
	CONSTANT OP_SHL : std_logic_vector(3 DOWNTO 0) := "1101";
	CONSTANT OP_SHR : std_logic_vector(3 DOWNTO 0) := "1110";
	CONSTANT OP_CMP : std_logic_vector(3 DOWNTO 0) := "1111";

BEGIN

	process(clk,rst)
		-- 17-bit accumulator so bit 16 captures carry / borrow.
		variable akku : unsigned(16 downto 0);
		variable res : std_logic_vector(15 downto 0);
		variable n, z, c, o : std_logic;

	begin
		-- RST should be active low. It resets the CPU.
		if (rst = '0') then
            result <= (others => '0');
            status <= (others => '0');
		elsif rising_edge(clk) then

		-- ALU / Data Path
		case op is
			when OP_ADD =>
				akku := resize(unsigned(a), 17) + resize(unsigned(b), 17);
			-- CMP is the same as SUB but we discard the result and only care about flags.
			when OP_SUB | OP_CMP =>
				akku := resize(unsigned(a), 17) + (not resize(unsigned(b), 17)) + 1;
			when OP_AND =>
				akku := resize(unsigned(a and b), 17);
			when OP_OR =>
				akku := resize(unsigned(a or b), 17);
			when OP_XOR =>
				akku := resize(unsigned(a xor b), 17);
			when OP_SHL =>
				akku := resize(unsigned(a), 17) sll 1;
			when OP_SHR =>
				akku := resize(unsigned(a), 17) srl 1;
			when others =>
				akku := (others => '0');
		end case;

		res := std_logic_vector(akku(15 downto 0));
		
		-- CMP only updates the flags, so hold the previous result value.
		if op /= OP_CMP then
			result <= res;
		end if;

		-- Status flags, bit order NZCO.
		n := res(15);                                            -- N
		if res = x"0000" then z := '1'; else z := '0'; end if;   -- Z
		c := akku(16);                                           -- C

		case op is
			when OP_ADD =>
				-- overflow if both inputs share a sign and the result flips it
				if (a(15) = b(15)) and (res(15) /= a(15)) then
					o := '1';
				else
					o := '0';
				end if;
			when OP_SUB | OP_CMP =>
				-- overflow if inputs differ in sign and result takes b's sign
				if (a(15) /= b(15)) and (res(15) /= a(15)) then
					o := '1';
				else
					o := '0';
				end if;
			when others =>
				o := '0';
		end case;

		status <= n & z & c & o;
	   end if;
	end process;
END main;
