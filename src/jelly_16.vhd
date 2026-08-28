library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.jelly_pkg.all;

entity jelly_16 is
    generic (
        PROG_FILE : string := ""; -- instruction memory image (hex, one word per line)
        DATA_FILE : string := ""; -- data memory image
        MEM_ADDR_WIDTH : integer := 12
    );
    port (
        clk : in std_logic;
        rst : in std_logic
    );
end entity jelly_16;

architecture main of jelly_16 is

    -- Program counter / fetch
    signal pc_out : std_logic_vector(JELLY_ADDR_WIDTH - 1 downto 0);
    signal pc_branch : std_logic;
    signal branch_target : std_logic_vector(JELLY_ADDR_WIDTH - 1 downto 0);
    signal instr : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);

    -- Instruction fields
    signal opcode : std_logic_vector(JELLY_OPCODE_BITS - 1 downto 0);
    signal rd_field : std_logic_vector(JELLY_REG_BITS - 1 downto 0);
    signal rs_field : std_logic_vector(JELLY_REG_BITS - 1 downto 0);
    signal rt_field : std_logic_vector(JELLY_REG_BITS - 1 downto 0);
    signal imm_value : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);
    signal cond_field : std_logic_vector(3 downto 0);

    -- Decoder control lines
    signal reg_write : std_logic;
    signal reg_a_src : std_logic_vector(1 downto 0);
    signal reg_b_src : std_logic_vector(1 downto 0);
    signal alu_a_src : std_logic_vector(1 downto 0);
    signal alu_b_src : std_logic_vector(1 downto 0);
    signal alu_op : std_logic_vector(3 downto 0);
    signal mem_read : std_logic;
    signal mem_write : std_logic;
    signal mem_to_reg : std_logic;
    signal jump : std_logic;
    signal halt : std_logic;
    signal status_we : std_logic;

    -- Register file / writeback
    signal rd_addr_a : std_logic_vector(JELLY_REG_BITS - 1 downto 0);
    signal rd_addr_b : std_logic_vector(JELLY_REG_BITS - 1 downto 0);
    signal rd_data_a : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);
    signal rd_data_b : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);
    signal wb_data : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);

    -- ALU
    signal alu_a : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);
    signal alu_b : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);
    signal alu_result : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);
    signal alu_status : std_logic_vector(3 downto 0);

    -- Data memory
    signal mem_q : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0);

    -- Condition matcher
    signal cond_met : std_logic;

    -- Status register
    signal status_out : std_logic_vector(3 downto 0);

    constant ZERO_WORD : std_logic_vector(JELLY_DATA_WIDTH - 1 downto 0) := (others => '0');

begin

    -------
    -- Program counter entity
    -- Holds the address of the next instruction to fetch.
    -------
    pc_inst: entity work.pc
    generic map (
        ADDR_WIDTH => JELLY_ADDR_WIDTH
    )
    port map (
        clk => clk,
        rst => rst,
        hold => halt, -- HALT freezes the program counter (just re-fetches HALT forever)
        branch => pc_branch,
        branch_target => branch_target,
        pc_out => pc_out
    );


    -- If the instruction is a jump and the condition is met, then branch to the target address; otherwise, continue sequentially.
    pc_branch <= jump and cond_met;
    -- Absolute jump target from the low 12 bits of the instruction.
    branch_target <= rd_data_a;

    -------
    -- Instruction memory entity
    -- It is a read-only memory (ROM) that holds the program. The instruction is fetched from the address in the program counter.
    -------
    imem: entity work.sram_async
    generic map (
        INIT_FILE => PROG_FILE,
        DATA_WIDTH => JELLY_DATA_WIDTH,
        ADDR_WIDTH => MEM_ADDR_WIDTH
    )
    port map (
        clk => clk,
        address => pc_out(MEM_ADDR_WIDTH - 1 downto 0),
        data => ZERO_WORD,
        wren => '0',
        q => instr
    );

    
    -- Instruction decode fields
    opcode <= instr(15 downto 12);
    rd_field <= instr(11 downto 8);
    rs_field <= instr(7 downto 4);
    rt_field <= instr(3 downto 0);
    cond_field <= instr(11 downto 8);
    imm_value <= instr(7 downto 0) & x"00" when opcode = OP_LUI else x"00" & instr(7 downto 0);

    -------
    -- Decoder entity
    -- Decodes the instruction opcode into control signals for the datapath. Is is combinational and does not hold state.
    -------
    decoder_inst: entity work.decoder
    generic map (
        OPCODE_BITS => JELLY_OPCODE_BITS
    )
    port map (
        opcode => opcode,
        reg_write => reg_write,
        reg_a_src => reg_a_src,
        reg_b_src => reg_b_src,
        alu_a_src => alu_a_src,
        alu_b_src => alu_b_src,
        alu_op => alu_op,
        mem_read => mem_read,
        mem_write => mem_write,
        mem_to_reg => mem_to_reg,
        jump => jump,
        halt => halt,
        status_we => status_we
    );

    -------
    -- Register file entity
    -- Contains 16 registers (R0-R15), each 16 bits wide
    -------

    -- Writeback mux
    -- Selects the data to write back into the register file based on the instruction type.
    wb_data <=
        mem_q      when mem_to_reg = '1'                       else  -- load result from data memory
        imm_value  when (opcode = OP_LDI or opcode = OP_LUI)   else  -- immediate / upper immediate
        rd_data_a  when opcode = OP_MOV                        else  -- register-to-register move
        alu_result;                                                  -- default is ALU output

    rd_addr_a <=
        rs_field when reg_a_src = REG_A_SRC_RS else
        rt_field when reg_a_src = REG_A_SRC_RT else
        rd_field;

    rd_addr_b <=
        rs_field when reg_b_src = REG_b_SRC_RS else
        rt_field when reg_b_src = REG_b_SRC_RT else
        rd_field;

    regfile_inst: entity work.regfile
    generic map (
        DATA_WIDTH => JELLY_DATA_WIDTH,
        ADDR_WIDTH => JELLY_REG_BITS
    )
    port map (
        clk => clk,
        rst => rst,
        rd_addr_a => rd_addr_a,
        rd_data_a => rd_data_a,
        rd_addr_b => rd_addr_b,
        rd_data_b => rd_data_b,
        wr_en => reg_write,
        wr_addr => rd_field,
        wr_data => wb_data
    );

    -------
    -- Status register entity
    -- Register holding the condition flags (NZCV in bits 3-0) updated by ALU ops and read by the condition matcher
    -------
    status_reg_inst: entity work.status_reg
    port map (
        clk => clk,
        rst => rst,
        status_in => alu_status,
        status_we => status_we,
        status_clr => '0', -- never clear the flags
        status_out => status_out
    );

    -- Condition matcher entity
    -- Compares the condition code from the instruction with the status register flags to determine if a
    -- conditional branch should be taken.
    cond_matcher_inst: entity work.cond_matcher
    port map (
        cond_code => cond_field,
        status => status_out,
        cond_met => cond_met
    );

    -------
    -- ALU entity
    -- Performs arithmetic and logical operations on the two 16-bit operands
    -- Also computes the condition flags (NZCV) for the status register
    -- When the source is set to immediate, the immediate value is used as the second operand; otherwise, the second register value is used.
    -------
    alu_a <=
        rd_data_a when alu_a_src = ALU_A_SRC_REG_A else
        rd_data_b when alu_a_src = ALU_A_SRC_REG_B else
        imm_value;
    alu_b <=
        rd_data_a when alu_b_src = ALU_B_SRC_REG_A else
        rd_data_b when alu_b_src = ALU_B_SRC_REG_B else
        imm_value;

    alu_inst: entity work.alu
    port map (
        a => alu_a,
        b => alu_b,
        op => alu_op,
        result => alu_result,
        status => alu_status
    );

    -------
    -- Memory entity
    -- Data memory (SRAM) with separate read and write ports
    -------
    dmem: entity work.sram_async
    generic map (
        INIT_FILE => DATA_FILE,
        DATA_WIDTH => JELLY_DATA_WIDTH,
        ADDR_WIDTH => MEM_ADDR_WIDTH
    )
    port map (
        clk => clk,
        address => rd_data_a(MEM_ADDR_WIDTH - 1 downto 0),
        data => rd_data_b,
        wren => mem_write,
        q => mem_q
    );

end architecture main;
