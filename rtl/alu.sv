// ============================================================================
// File: alu.sv
// Description: Arithmetic Logic Unit (ALU) for RV32I Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module alu (
  input  logic [31:0] operand_a,
  input  logic [31:0] operand_b,
  input  alu_op_e     alu_op,
  output logic [31:0] alu_result,
  output logic        zero_flag
);

  always_comb begin
    case (alu_op)
      ALU_ADD:    alu_result = operand_a + operand_b;
      ALU_SUB:    alu_result = operand_a - operand_b;
      ALU_SLL:    alu_result = operand_a << operand_b[4:0];
      ALU_SLT:    alu_result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
      ALU_SLTU:   alu_result = (operand_a < operand_b) ? 32'd1 : 32'd0;
      ALU_XOR:    alu_result = operand_a ^ operand_b;
      ALU_SRL:    alu_result = operand_a >> operand_b[4:0];
      ALU_SRA:    alu_result = $signed(operand_a) >>> operand_b[4:0];
      ALU_OR:     alu_result = operand_a | operand_b;
      ALU_AND:    alu_result = operand_a & operand_b;
      ALU_COPY_B: alu_result = operand_b;
      default:    alu_result = 32'd0;
    endcase
  end

  assign zero_flag = (alu_result == 32'd0);

endmodule
