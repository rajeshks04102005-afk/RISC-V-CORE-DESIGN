// ============================================================================
// File: execute_stage.sv
// Description: Execute (EX) Stage for 5-Stage RV32I Core with Forwarding MUXes
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module execute_stage (
  input  logic [31:0]      pc_ex,
  input  logic [31:0]      rs1_data_ex,
  input  logic [31:0]      rs2_data_ex,
  input  logic [31:0]      imm_ex,
  input  control_signals_t ctrl_ex,

  // Forwarded Data Inputs
  input  forward_e         forward_a,
  input  forward_e         forward_b,
  input  logic [31:0]      alu_result_mem,  // Forwarded from EX/MEM stage
  input  logic [31:0]      write_data_wb,   // Forwarded from MEM/WB stage

  // Outputs
  output logic [31:0]      alu_result_ex,
  output logic [31:0]      write_data_mem_ex, // Forwarded RS2 data for store operations
  output logic [31:0]      branch_target_ex,
  output logic             pcsrc_ex
);

  logic [31:0] operand_a_forwarded;
  logic [31:0] operand_b_forwarded;
  logic [31:0] alu_operand_a;
  logic [31:0] alu_operand_b;
  logic        zero_flag;
  logic        branch_taken;

  // --------------------------------------------------------------------------
  // Forwarding MUXes for RS1 and RS2
  // --------------------------------------------------------------------------
  always_comb begin
    case (forward_a)
      FORWARD_EX:   operand_a_forwarded = alu_result_mem;
      FORWARD_MEM:  operand_a_forwarded = write_data_wb;
      default:      operand_a_forwarded = rs1_data_ex;
    endcase

    case (forward_b)
      FORWARD_EX:   operand_b_forwarded = alu_result_mem;
      FORWARD_MEM:  operand_b_forwarded = write_data_wb;
      default:      operand_b_forwarded = rs2_data_ex;
    endcase
  end

  assign write_data_mem_ex = operand_b_forwarded;

  // --------------------------------------------------------------------------
  // ALU Operand Input MUXes
  // --------------------------------------------------------------------------
  always_comb begin
    // Source A MUX
    case (ctrl_ex.alu_src_a)
      ALU_SRC_PC:   alu_operand_a = pc_ex;
      default:      alu_operand_a = operand_a_forwarded;
    endcase

    // Source B MUX
    case (ctrl_ex.alu_src_b)
      ALU_SRC_IMM:  alu_operand_b = imm_ex;
      ALU_SRC_FOUR: alu_operand_b = 32'd4;
      default:      alu_operand_b = operand_b_forwarded;
    endcase
  end

  // ALU Instantiation
  alu u_alu (
    .operand_a(alu_operand_a),
    .operand_b(alu_operand_b),
    .alu_op(ctrl_ex.alu_op),
    .alu_result(alu_result_ex),
    .zero_flag(zero_flag)
  );

  // --------------------------------------------------------------------------
  // Branch Evaluator & Branch/Jump Target Generation
  // --------------------------------------------------------------------------
  always_comb begin
    branch_taken = 1'b0;
    if (ctrl_ex.branch) begin
      case (ctrl_ex.mem_funct3)
        FUNCT3_BEQ:  branch_taken = (operand_a_forwarded == operand_b_forwarded);
        FUNCT3_BNE:  branch_taken = (operand_a_forwarded != operand_b_forwarded);
        FUNCT3_BLT:  branch_taken = ($signed(operand_a_forwarded) < $signed(operand_b_forwarded));
        FUNCT3_BGE:  branch_taken = ($signed(operand_a_forwarded) >= $signed(operand_b_forwarded));
        FUNCT3_BLTU: branch_taken = (operand_a_forwarded < operand_b_forwarded);
        FUNCT3_BGEU: branch_taken = (operand_a_forwarded >= operand_b_forwarded);
        default:     branch_taken = 1'b0;
      endcase
    end
  end

  assign pcsrc_ex = branch_taken | ctrl_ex.jal | ctrl_ex.jalr;

  // Branch / Jump Target MUX (JALR uses register + imm & ~1, JAL/Branch uses PC + imm)
  assign branch_target_ex = ctrl_ex.jalr ? ((operand_a_forwarded + imm_ex) & ~32'h1) :
                                           (pc_ex + imm_ex);

endmodule
