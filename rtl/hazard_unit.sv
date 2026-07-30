// ============================================================================
// File: hazard_unit.sv
// Description: Hazard Detection & Data Forwarding Unit for RV32I Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module hazard_unit (
  // Addresses from ID Stage
  input  logic [4:0] rs1_id,
  input  logic [4:0] rs2_id,

  // Addresses and Controls from EX Stage
  input  logic [4:0] rs1_ex,
  input  logic [4:0] rs2_ex,
  input  logic [4:0] rd_ex,
  input  logic       mem_read_ex,
  input  logic       pcsrc_ex,       // Branch/Jump taken in EX

  // Addresses and Controls from MEM Stage
  input  logic [4:0] rd_mem,
  input  logic       reg_write_mem,

  // Addresses and Controls from WB Stage
  input  logic [4:0] rd_wb,
  input  logic       reg_write_wb,

  // Forwarding Output Signals
  output forward_e   forward_a,
  output forward_e   forward_b,

  // Pipeline Control Signals
  output logic       stall_if,
  output logic       stall_id,
  output logic       flush_if_id,
  output logic       flush_id_ex
);

  // --------------------------------------------------------------------------
  // 1. Data Forwarding Logic (EX -> EX and MEM -> EX)
  // --------------------------------------------------------------------------
  always_comb begin
    // Forwarding for Operand A (RS1)
    if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex)) begin
      forward_a = FORWARD_EX;
    end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex)) begin
      forward_a = FORWARD_MEM;
    end else begin
      forward_a = FORWARD_NONE;
    end

    // Forwarding for Operand B (RS2)
    if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex)) begin
      forward_b = FORWARD_EX;
    end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex)) begin
      forward_b = FORWARD_MEM;
    end else begin
      forward_b = FORWARD_NONE;
    end
  end

  // --------------------------------------------------------------------------
  // 2. Load-Use Stall Logic
  // --------------------------------------------------------------------------
  logic load_use_stall;
  assign load_use_stall = mem_read_ex && (rd_ex != 5'd0) &&
                          ((rd_ex == rs1_id) || (rd_ex == rs2_id));

  // --------------------------------------------------------------------------
  // 3. Pipeline Register Control Outputs (Stall & Flush)
  // --------------------------------------------------------------------------
  always_comb begin
    stall_if    = 1'b0;
    stall_id    = 1'b0;
    flush_if_id = 1'b0;
    flush_id_ex = 1'b0;

    if (pcsrc_ex) begin
      // Branch / Jump taken: Flush wrong-path instructions in IF/ID and ID/EX
      flush_if_id = 1'b1;
      flush_id_ex = 1'b1;
    end else if (load_use_stall) begin
      // Load-Use hazard: Stall IF and ID, insert NOP into EX stage
      stall_if    = 1'b1;
      stall_id    = 1'b1;
      flush_id_ex = 1'b1;
    end
  end

endmodule
