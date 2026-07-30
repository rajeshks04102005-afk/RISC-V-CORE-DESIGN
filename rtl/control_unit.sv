// ============================================================================
// File: control_unit.sv
// Description: Main Decoder & ALU Control Unit for RV32I Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module control_unit (
  input  logic [6:0]       opcode,
  input  logic [2:0]       funct3,
  input  logic [6:0]       funct7,
  output control_signals_t ctrl
);

  always_comb begin
    // Defaults (No-Op state)
    ctrl.reg_write  = 1'b0;
    ctrl.wb_src     = WB_ALU;
    ctrl.mem_read   = 1'b0;
    ctrl.mem_write  = 1'b0;
    ctrl.mem_funct3 = funct3;
    ctrl.branch     = 1'b0;
    ctrl.jal        = 1'b0;
    ctrl.jalr       = 1'b0;
    ctrl.alu_op     = ALU_ADD;
    ctrl.alu_src_a  = ALU_SRC_REG1;
    ctrl.alu_src_b  = ALU_SRC_REG2;

    case (opcode)
      OPCODE_R_TYPE: begin
        ctrl.reg_write  = 1'b1;
        ctrl.wb_src     = WB_ALU;
        ctrl.alu_src_a  = ALU_SRC_REG1;
        ctrl.alu_src_b  = ALU_SRC_REG2;

        case (funct3)
          FUNCT3_ADD_SUB: ctrl.alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
          FUNCT3_SLL:     ctrl.alu_op = ALU_SLL;
          FUNCT3_SLT:     ctrl.alu_op = ALU_SLT;
          FUNCT3_SLTU:    ctrl.alu_op = ALU_SLTU;
          FUNCT3_XOR:     ctrl.alu_op = ALU_XOR;
          FUNCT3_SRL_SRA: ctrl.alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
          FUNCT3_OR:      ctrl.alu_op = ALU_OR;
          FUNCT3_AND:     ctrl.alu_op = ALU_AND;
          default:        ctrl.alu_op = ALU_ADD;
        endcase
      end

      OPCODE_I_TYPE: begin
        ctrl.reg_write  = 1'b1;
        ctrl.wb_src     = WB_ALU;
        ctrl.alu_src_a  = ALU_SRC_REG1;
        ctrl.alu_src_b  = ALU_SRC_IMM;

        case (funct3)
          FUNCT3_ADD_SUB: ctrl.alu_op = ALU_ADD;
          FUNCT3_SLL:     ctrl.alu_op = ALU_SLL;
          FUNCT3_SLT:     ctrl.alu_op = ALU_SLT;
          FUNCT3_SLTU:    ctrl.alu_op = ALU_SLTU;
          FUNCT3_XOR:     ctrl.alu_op = ALU_XOR;
          FUNCT3_SRL_SRA: ctrl.alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
          FUNCT3_OR:      ctrl.alu_op = ALU_OR;
          FUNCT3_AND:     ctrl.alu_op = ALU_AND;
          default:        ctrl.alu_op = ALU_ADD;
        endcase
      end

      OPCODE_LOAD: begin
        ctrl.reg_write = 1'b1;
        ctrl.wb_src    = WB_MEM;
        ctrl.mem_read  = 1'b1;
        ctrl.alu_src_a = ALU_SRC_REG1;
        ctrl.alu_src_b = ALU_SRC_IMM;
        ctrl.alu_op    = ALU_ADD; // Address calculation
      end

      OPCODE_STORE: begin
        ctrl.mem_write = 1'b1;
        ctrl.alu_src_a = ALU_SRC_REG1;
        ctrl.alu_src_b = ALU_SRC_IMM;
        ctrl.alu_op    = ALU_ADD; // Address calculation
      end

      OPCODE_BRANCH: begin
        ctrl.branch    = 1'b1;
        ctrl.alu_src_a = ALU_SRC_REG1;
        ctrl.alu_src_b = ALU_SRC_REG2;
        ctrl.alu_op    = ALU_SUB; // Compare operands via subtraction
      end

      OPCODE_JAL: begin
        ctrl.reg_write = 1'b1;
        ctrl.jal       = 1'b1;
        ctrl.wb_src    = WB_PC4;
        ctrl.alu_src_a = ALU_SRC_PC;
        ctrl.alu_src_b = ALU_SRC_IMM;
        ctrl.alu_op    = ALU_ADD;
      end

      OPCODE_JALR: begin
        ctrl.reg_write = 1'b1;
        ctrl.jalr      = 1'b1;
        ctrl.wb_src    = WB_PC4;
        ctrl.alu_src_a = ALU_SRC_REG1;
        ctrl.alu_src_b = ALU_SRC_IMM;
        ctrl.alu_op    = ALU_ADD;
      end

      OPCODE_LUI: begin
        ctrl.reg_write = 1'b1;
        ctrl.wb_src    = WB_ALU;
        ctrl.alu_src_a = ALU_SRC_REG1;
        ctrl.alu_src_b = ALU_SRC_IMM;
        ctrl.alu_op    = ALU_COPY_B; // Pass immediate to destination
      end

      OPCODE_AUIPC: begin
        ctrl.reg_write = 1'b1;
        ctrl.wb_src    = WB_ALU;
        ctrl.alu_src_a = ALU_SRC_PC;
        ctrl.alu_src_b = ALU_SRC_IMM;
        ctrl.alu_op    = ALU_ADD;
      end

      default: begin
        // Keep defaults
      end
    endcase
  end

endmodule
