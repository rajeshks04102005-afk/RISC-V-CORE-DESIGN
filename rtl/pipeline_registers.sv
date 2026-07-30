// ============================================================================
// File: pipeline_registers.sv
// Description: Pipeline Registers (IF/ID, ID/EX, EX/MEM, MEM/WB) for RV32I Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

// ----------------------------------------------------------------------------
// IF/ID Pipeline Register
// ----------------------------------------------------------------------------
module if_id_reg (
  input  logic        clk,
  input  logic        reset,
  input  logic        stall_id,
  input  logic        flush_if_id,
  input  logic [31:0] pc_if,
  input  logic [31:0] pc_plus_4_if,
  input  logic [31:0] instr_if,
  output logic [31:0] pc_id,
  output logic [31:0] pc_plus_4_id,
  output logic [31:0] instr_id
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset || flush_if_id) begin
      pc_id        <= 32'd0;
      pc_plus_4_id <= 32'd0;
      instr_id     <= 32'h0000_0013; // NOP (addi x0, x0, 0)
    end else if (!stall_id) begin
      pc_id        <= pc_if;
      pc_plus_4_id <= pc_plus_4_if;
      instr_id     <= instr_if;
    end
  end

endmodule


// ----------------------------------------------------------------------------
// ID/EX Pipeline Register
// ----------------------------------------------------------------------------
module id_ex_reg (
  input  logic             clk,
  input  logic             reset,
  input  logic             flush_id_ex,
  input  logic [31:0]      pc_id,
  input  logic [31:0]      pc_plus_4_id,
  input  logic [31:0]      rs1_data_id,
  input  logic [31:0]      rs2_data_id,
  input  logic [31:0]      imm_id,
  input  logic [4:0]       rs1_addr_id,
  input  logic [4:0]       rs2_addr_id,
  input  logic [4:0]       rd_addr_id,
  input  control_signals_t ctrl_id,

  output logic [31:0]      pc_ex,
  output logic [31:0]      pc_plus_4_ex,
  output logic [31:0]      rs1_data_ex,
  output logic [31:0]      rs2_data_ex,
  output logic [31:0]      imm_ex,
  output logic [4:0]       rs1_addr_ex,
  output logic [4:0]       rs2_addr_ex,
  output logic [4:0]       rd_addr_ex,
  output control_signals_t ctrl_ex
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset || flush_id_ex) begin
      pc_ex        <= 32'd0;
      pc_plus_4_ex <= 32'd0;
      rs1_data_ex  <= 32'd0;
      rs2_data_ex  <= 32'd0;
      imm_ex       <= 32'd0;
      rs1_addr_ex  <= 5'd0;
      rs2_addr_ex  <= 5'd0;
      rd_addr_ex   <= 5'd0;
      ctrl_ex      <= '0; // Clear control signals (Bubble / NOP)
    end else begin
      pc_ex        <= pc_id;
      pc_plus_4_ex <= pc_plus_4_id;
      rs1_data_ex  <= rs1_data_id;
      rs2_data_ex  <= rs2_data_id;
      imm_ex       <= imm_id;
      rs1_addr_ex  <= rs1_addr_id;
      rs2_addr_ex  <= rs2_addr_id;
      rd_addr_ex   <= rd_addr_id;
      ctrl_ex      <= ctrl_id;
    end
  end

endmodule


// ----------------------------------------------------------------------------
// EX/MEM Pipeline Register
// ----------------------------------------------------------------------------
module ex_mem_reg (
  input  logic             clk,
  input  logic             reset,
  input  logic [31:0]      pc_plus_4_ex,
  input  logic [31:0]      alu_result_ex,
  input  logic [31:0]      write_data_mem_ex,
  input  logic [4:0]       rd_addr_ex,
  input  control_signals_t ctrl_ex,

  output logic [31:0]      pc_plus_4_mem,
  output logic [31:0]      alu_result_mem,
  output logic [31:0]      write_data_mem,
  output logic [4:0]       rd_addr_mem,
  output control_signals_t ctrl_mem
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      pc_plus_4_mem  <= 32'd0;
      alu_result_mem <= 32'd0;
      write_data_mem <= 32'd0;
      rd_addr_mem    <= 5'd0;
      ctrl_mem       <= '0;
    end else begin
      pc_plus_4_mem  <= pc_plus_4_ex;
      alu_result_mem <= alu_result_ex;
      write_data_mem <= write_data_mem_ex;
      rd_addr_mem    <= rd_addr_ex;
      ctrl_mem       <= ctrl_ex;
    end
  end

endmodule


// ----------------------------------------------------------------------------
// MEM/WB Pipeline Register
// ----------------------------------------------------------------------------
module mem_wb_reg (
  input  logic             clk,
  input  logic             reset,
  input  logic [31:0]      pc_plus_4_mem,
  input  logic [31:0]      alu_result_mem,
  input  logic [31:0]      read_data_mem_formatted,
  input  logic [4:0]       rd_addr_mem,
  input  control_signals_t ctrl_mem,

  output logic [31:0]      pc_plus_4_wb,
  output logic [31:0]      alu_result_wb,
  output logic [31:0]      read_data_wb,
  output logic [4:0]       rd_addr_wb,
  output control_signals_t ctrl_wb
);

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      pc_plus_4_wb  <= 32'd0;
      alu_result_wb <= 32'd0;
      read_data_wb  <= 32'd0;
      rd_addr_wb    <= 5'd0;
      ctrl_wb       <= '0;
    end else begin
      pc_plus_4_wb  <= pc_plus_4_mem;
      alu_result_wb <= alu_result_mem;
      read_data_wb  <= read_data_mem_formatted;
      rd_addr_wb    <= rd_addr_mem;
      ctrl_wb       <= ctrl_mem;
    end
  end

endmodule
