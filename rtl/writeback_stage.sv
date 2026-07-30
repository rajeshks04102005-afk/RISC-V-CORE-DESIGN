// ============================================================================
// File: writeback_stage.sv
// Description: Writeback (WB) Stage MUX for 5-Stage RV32I Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module writeback_stage (
  input  logic [31:0]      alu_result_wb,
  input  logic [31:0]      read_data_wb,
  input  logic [31:0]      pc_plus_4_wb,
  input  control_signals_t ctrl_wb,
  output logic [31:0]      write_data_wb
);

  always_comb begin
    case (ctrl_wb.wb_src)
      WB_MEM:  write_data_wb = read_data_wb;
      WB_PC4:  write_data_wb = pc_plus_4_wb;
      default: write_data_wb = alu_result_wb; // WB_ALU
    endcase
  end

endmodule
