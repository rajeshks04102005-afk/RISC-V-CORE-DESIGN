// ============================================================================
// File: rv32i_pkg.sv
// Description: SystemVerilog Package for RV32I 5-Stage Pipelined RISC-V Core
// ============================================================================

package rv32i_pkg;

  // --------------------------------------------------------------------------
  // Opcodes (Bits 6:0)
  // --------------------------------------------------------------------------
  typedef enum logic [6:0] {
    OPCODE_R_TYPE = 7'b0110011, // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    OPCODE_I_TYPE = 7'b0010011, // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    OPCODE_LOAD   = 7'b0000011, // LB, LH, LW, LBU, LHU
    OPCODE_STORE  = 7'b0100011, // SB, SH, SW
    OPCODE_BRANCH = 7'b1100011, // BEQ, BNE, BLT, BGE, BLTU, BGEU
    OPCODE_JAL    = 7'b1101111, // JAL
    OPCODE_JALR   = 7'b1100111, // JALR
    OPCODE_LUI    = 7'b0110111, // LUI
    OPCODE_AUIPC  = 7'b0010111  // AUIPC
  } opcode_e;

  // --------------------------------------------------------------------------
  // Funct3 Encoding
  // --------------------------------------------------------------------------
  // R-Type / I-Type Funct3
  localparam logic [2:0] FUNCT3_ADD_SUB = 3'b000;
  localparam logic [2:0] FUNCT3_SLL     = 3'b001;
  localparam logic [2:0] FUNCT3_SLT     = 3'b010;
  localparam logic [2:0] FUNCT3_SLTU    = 3'b011;
  localparam logic [2:0] FUNCT3_XOR     = 3'b100;
  localparam logic [2:0] FUNCT3_SRL_SRA = 3'b101;
  localparam logic [2:0] FUNCT3_OR      = 3'b110;
  localparam logic [2:0] FUNCT3_AND     = 3'b111;

  // Branch Funct3
  localparam logic [2:0] FUNCT3_BEQ  = 3'b000;
  localparam logic [2:0] FUNCT3_BNE  = 3'b001;
  localparam logic [2:0] FUNCT3_BLT  = 3'b100;
  localparam logic [2:0] FUNCT3_BGE  = 3'b101;
  localparam logic [2:0] FUNCT3_BLTU = 3'b110;
  localparam logic [2:0] FUNCT3_BGEU = 3'b111;

  // Load/Store Funct3
  localparam logic [2:0] FUNCT3_LB  = 3'b000;
  localparam logic [2:0] FUNCT3_LH  = 3'b001;
  localparam logic [2:0] FUNCT3_LW  = 3'b010;
  localparam logic [2:0] FUNCT3_LBU = 3'b100;
  localparam logic [2:0] FUNCT3_LHU = 3'b101;
  localparam logic [2:0] FUNCT3_SB  = 3'b000;
  localparam logic [2:0] FUNCT3_SH  = 3'b001;
  localparam logic [2:0] FUNCT3_SW  = 3'b010;

  // Funct7 Encoding
  localparam logic [6:0] FUNCT7_ADD = 7'b0000000;
  localparam logic [6:0] FUNCT7_SUB = 7'b0100000;
  localparam logic [6:0] FUNCT7_SRL = 7'b0000000;
  localparam logic [6:0] FUNCT7_SRA = 7'b0100000;

  // --------------------------------------------------------------------------
  // ALU Control Operations
  // --------------------------------------------------------------------------
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_SLL  = 4'b0010,
    ALU_SLT  = 4'b0011,
    ALU_SLTU = 4'b0100,
    ALU_XOR  = 4'b0101,
    ALU_SRL  = 4'b0110,
    ALU_SRA  = 4'b0111,
    ALU_OR   = 4'b1000,
    ALU_AND  = 4'b1001,
    ALU_COPY_B = 4'b1010 // For LUI / pass immediate directly
  } alu_op_e;

  // --------------------------------------------------------------------------
  // MUX Select Controls
  // --------------------------------------------------------------------------
  typedef enum logic [1:0] {
    ALU_SRC_REG2 = 2'b00,
    ALU_SRC_IMM  = 2'b01,
    ALU_SRC_FOUR = 2'b10
  } alu_src_b_e;

  typedef enum logic {
    ALU_SRC_REG1 = 1'b0,
    ALU_SRC_PC   = 1'b1
  } alu_src_a_e;

  typedef enum logic [1:0] {
    WB_ALU  = 2'b00,
    WB_MEM  = 2'b01,
    WB_PC4  = 2'b10
  } wb_src_e;

  // Forwarding MUX Selects
  typedef enum logic [1:0] {
    FORWARD_NONE = 2'b00,
    FORWARD_EX   = 2'b01, // Forward from EX/MEM stage
    FORWARD_MEM  = 2'b10  // Forward from MEM/WB stage
  } forward_e;

  // --------------------------------------------------------------------------
  // Control Signal Bundle Structure
  // --------------------------------------------------------------------------
  typedef struct packed {
    logic       reg_write;
    wb_src_e    wb_src;
    logic       mem_read;
    logic       mem_write;
    logic [2:0] mem_funct3;
    logic       branch;
    logic       jal;
    logic       jalr;
    alu_op_e    alu_op;
    alu_src_a_e alu_src_a;
    alu_src_b_e alu_src_b;
  } control_signals_t;

endpackage: rv32i_pkg
