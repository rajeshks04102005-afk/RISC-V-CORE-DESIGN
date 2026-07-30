// ============================================================================
// File: decode_stage.sv
// Description: Instruction Decode (ID) Stage for 5-Stage RV32I Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module decode_stage (
  input  logic        clk,
  input  logic        reset,
  input  logic [31:0] instr_id,
  input  logic [31:0] pc_id,
  input  logic [31:0] pc_plus_4_id,
  
  // Writeback Interface
  input  logic        reg_write_wb,
  input  logic [4:0]  rd_addr_wb,
  input  logic [31:0] write_data_wb,

  // Decoded Outputs
  output control_signals_t ctrl_id,
  output logic [31:0] rs1_data_id,
  output logic [31:0] rs2_data_id,
  output logic [31:0] imm_id,
  output logic [4:0]  rs1_addr_id,
  output logic [4:0]  rs2_addr_id,
  output logic [4:0]  rd_addr_id,
  output logic [2:0]  funct3_id,
  output logic [6:0]  funct7_id
);

  assign rs1_addr_id = instr_id[19:15];
  assign rs2_addr_id = instr_id[24:20];
  assign rd_addr_id  = instr_id[11:7];
  assign funct3_id   = instr_id[14:12];
  assign funct7_id   = instr_id[31:25];

  // Control Unit Instantiation
  control_unit u_control_unit (
    .opcode(instr_id[6:0]),
    .funct3(funct3_id),
    .funct7(funct7_id),
    .ctrl(ctrl_id)
  );

  // Register File Instantiation
  register_file u_register_file (
    .clk(clk),
    .reset(reset),
    .reg_write_wb(reg_write_wb),
    .rs1_addr(rs1_addr_id),
    .rs2_addr(rs2_addr_id),
    .rd_addr_wb(rd_addr_wb),
    .write_data_wb(write_data_wb),
    .rs1_data(rs1_data_id),
    .rs2_data(rs2_data_id)
  );

  // Immediate Generator Instantiation
  imm_gen u_imm_gen (
    .instr(instr_id),
    .imm_ext(imm_id)
  );

endmodule
