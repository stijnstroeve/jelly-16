library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pc_tb is
end entity pc_tb;

architecture sim of pc_tb is

    -- Keep the counter narrow so wraparound is reachable in a few clocks
    -- (the 4-bit counter wraps 15 -> 0). The DUT logic is width-agnostic.
    constant TB_ADDR_WIDTH : integer := 4;

    constant CLK_PERIOD : time := 10 ns;

    -- DUT signals
    signal clk : std_logic := '0';
    signal rst : std_logic := '1'; -- active low: '0' resets, '1' runs
    signal hold : std_logic := '0';
    signal branch : std_logic := '0';
    signal branch_target : std_logic_vector(TB_ADDR_WIDTH - 1 downto 0) := (others => '0');
    signal pc_out : std_logic_vector(TB_ADDR_WIDTH - 1 downto 0);

    signal sim_done : boolean := false;
begin

    -- Device under test
    dut: entity work.pc
    generic map (
        ADDR_WIDTH => TB_ADDR_WIDTH
    )
    port map (
        clk => clk,
        rst => rst,
        hold => hold,
        branch => branch,
        branch_target => branch_target,
        pc_out => pc_out
    );

    -- Clock generation
    clk_gen: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process clk_gen;

    -- Stimulus and checking
    stim: process

        -- Advance one clock and let the registered output settle.
        procedure step is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure step;

        -- Compare pc_out against an expected integer address.
        procedure check_pc(constant expected : in integer; constant name : in string) is
            variable exp_slv : std_logic_vector(TB_ADDR_WIDTH - 1 downto 0);
        begin
            exp_slv := std_logic_vector(to_unsigned(expected, TB_ADDR_WIDTH));
            assert pc_out = exp_slv report name & ": expected 0x" & to_hstring(unsigned(exp_slv)) & " got 0x" & to_hstring(unsigned(pc_out)) severity error;
        end procedure check_pc;

    begin
        -- ===== Initial value is zero =====
        -- pc_reg is initialised to 0; pc_out reflects it before the first edge.
        wait for 1 ns;
        check_pc(0, "INIT pc = 0");

        -- ===== Free-running increment =====
        -- rst='1', hold='0', branch='0': the counter increments every edge.
        step;
        check_pc(1, "INCR pc = 1");
        step;
        check_pc(2, "INCR pc = 2");
        step;
        check_pc(3, "INCR pc = 3");

        -- ===== Hold freezes the current address =====
        hold <= '1';
        step;
        check_pc(3, "HOLD pc stays 3");
        step;
        check_pc(3, "HOLD pc still 3 after second edge");
        hold <= '0';
        step;
        check_pc(4, "RESUME pc = 4 after hold released");

        -- ===== Branch loads branch_target =====
        branch_target <= std_logic_vector(to_unsigned(10, TB_ADDR_WIDTH));
        branch <= '1';
        step;
        check_pc(10, "BRANCH pc = 10");
        branch <= '0';
        step;
        check_pc(11, "BRANCH then increment pc = 11");

        -- ===== Branch to address 0 =====
        branch_target <= std_logic_vector(to_unsigned(0, TB_ADDR_WIDTH));
        branch <= '1';
        step;
        check_pc(0, "BRANCH to 0");
        branch <= '0';

        -- ===== Priority: hold beats branch =====
        -- With both hold and branch asserted the counter must hold, not branch.
        branch_target <= std_logic_vector(to_unsigned(5, TB_ADDR_WIDTH));
        hold <= '1';
        branch <= '1';
        step;
        check_pc(0, "PRIORITY hold over branch: pc stays 0");
        hold <= '0';
        branch <= '0';

        -- ===== Priority: reset beats everything =====
        -- First move off zero so the reset is observable.
        step;
        check_pc(1, "pre-reset increment pc = 1");
        branch_target <= std_logic_vector(to_unsigned(7, TB_ADDR_WIDTH));
        rst <= '0'; -- active-low reset asserted
        hold <= '1';
        branch <= '1';
        step;
        check_pc(0, "PRIORITY reset over hold/branch: pc = 0");
        rst <= '1';
        hold <= '0';
        branch <= '0';

        -- ===== Wraparound: max value increments back to 0 =====
        -- Branch straight to the top of the range, then let it roll over.
        branch_target <= std_logic_vector(to_unsigned(2 ** TB_ADDR_WIDTH - 1, TB_ADDR_WIDTH));
        branch <= '1';
        step;
        check_pc(2 ** TB_ADDR_WIDTH - 1, "WRAP setup pc = max (15)");
        branch <= '0';
        step;
        check_pc(0, "WRAP pc 15 -> 0");

        report "PC testbench completed" severity note;
        sim_done <= true;
        wait;
    end process stim;

end architecture sim;
