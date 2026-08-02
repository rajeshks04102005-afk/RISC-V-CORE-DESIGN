// ============================================================================
// File: imm_gen.sv
// Description: Immediate Generator (Sign Extender) for RV32I Core
// ============================================================================

`timescale 1ns / 1ps

module imm_gen (
  input  logic [31:0] instr,
  output logic [31:0] imm_ext
);

  logic [6:0] opcode;
  assign opcode = instr[6:0];

  always_comb begin
    case (opcode)
      // I-Type (ADDI, LW, JALR, etc.)
      7'b0010011, 7'b0000011, 7'b1100111: begin
        imm_ext = {{20{instr[31]}}, instr[31:20]};
      end

      // S-Type (SW, SH, SB)
      7'b0100011: begin
        imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
      end

      // B-Type (BEQ, BNE, BLT, BGE, etc.)
      7'b1100011: begin
        imm_ext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
      end

      // U-Type (LUI, AUIPC)
      7'b0110111, 7'b0010111: begin
        imm_ext = {instr[31:12], 12'b0};
      end

      // J-Type (JAL)
      7'b1101111: begin
        imm_ext = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
      end

      default: begin
        imm_ext = 32'd0;
      end
    endcase
  end

endmodule
