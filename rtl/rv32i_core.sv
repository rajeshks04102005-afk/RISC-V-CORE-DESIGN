// ============================================================================
// File: rv32i_core.sv
// Description: Top-Level 5-Stage Pipelined RV32I RISC-V CPU Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module rv32i_core (
  input  logic        clk,
  input  logic        reset,

  // Instruction Memory Interface
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,

  // Data Memory Interface
  output logic [31:0] dmem_addr,
  output logic [31:0] dmem_wdata,
  output logic [3:0]  dmem_byte_enable,
  output logic        dmem_read_en,
  output logic        dmem_write_en,
  input  logic [31:0] dmem_rdata
);

  // --------------------------------------------------------------------------
  // Inter-Stage Wires & Signals
  // --------------------------------------------------------------------------

  // Hazard Control Signals
  forward_e forward_a, forward_b;
  logic     stall_if, stall_id, flush_if_id, flush_id_ex;

  // IF Stage Signals
  logic [31:0] pc_if, pc_plus_4_if;

  // IF/ID Pipeline Register Outputs
  logic [31:0] pc_id, pc_plus_4_id, instr_id;

  // ID Stage Outputs
  control_signals_t ctrl_id;
  logic [31:0]      rs1_data_id, rs2_data_id, imm_id;
  logic [4:0]       rs1_addr_id, rs2_addr_id, rd_addr_id;
  logic [2:0]       funct3_id;
  logic [6:0]       funct7_id;

  // ID/EX Pipeline Register Outputs
  logic [31:0]      pc_ex, pc_plus_4_ex, rs1_data_ex, rs2_data_ex, imm_ex;
  logic [4:0]       rs1_addr_ex, rs2_addr_ex, rd_addr_ex;
  control_signals_t ctrl_ex;

  // EX Stage Outputs
  logic [31:0] alu_result_ex, write_data_mem_ex, branch_target_ex;
  logic        pcsrc_ex;

  // EX/MEM Pipeline Register Outputs
  logic [31:0]      pc_plus_4_mem, alu_result_mem, write_data_mem;
  logic [4:0]       rd_addr_mem;
  control_signals_t ctrl_mem;

  // MEM Stage Outputs
  logic [31:0] read_data_mem_formatted;

  // MEM/WB Pipeline Register Outputs
  logic [31:0]      pc_plus_4_wb, alu_result_wb, read_data_wb;
  logic [4:0]       rd_addr_wb;
  control_signals_t ctrl_wb;

  // WB Stage Output
  logic [31:0] write_data_wb;


  // --------------------------------------------------------------------------
  // 1. Instruction Fetch (IF) Stage & Pipeline Register
  // --------------------------------------------------------------------------
  fetch_stage u_fetch_stage (
    .clk(clk),
    .reset(reset),
    .stall_if(stall_if),
    .pcsrc(pcsrc_ex),
    .branch_target(branch_target_ex),
    .pc_if(pc_if),
    .pc_plus_4_if(pc_plus_4_if),
    .imem_addr(imem_addr)
  );

  if_id_reg u_if_id_reg (
    .clk(clk),
    .reset(reset),
    .stall_id(stall_id),
    .flush_if_id(flush_if_id),
    .pc_if(pc_if),
    .pc_plus_4_if(pc_plus_4_if),
    .instr_if(imem_rdata),
    .pc_id(pc_id),
    .pc_plus_4_id(pc_plus_4_id),
    .instr_id(instr_id)
  );


  // --------------------------------------------------------------------------
  // 2. Instruction Decode (ID) Stage & Pipeline Register
  // --------------------------------------------------------------------------
  decode_stage u_decode_stage (
    .clk(clk),
    .reset(reset),
    .instr_id(instr_id),
    .pc_id(pc_id),
    .pc_plus_4_id(pc_plus_4_id),
    .reg_write_wb(ctrl_wb.reg_write),
    .rd_addr_wb(rd_addr_wb),
    .write_data_wb(write_data_wb),
    .ctrl_id(ctrl_id),
    .rs1_data_id(rs1_data_id),
    .rs2_data_id(rs2_data_id),
    .imm_id(imm_id),
    .rs1_addr_id(rs1_addr_id),
    .rs2_addr_id(rs2_addr_id),
    .rd_addr_id(rd_addr_id),
    .funct3_id(funct3_id),
    .funct7_id(funct7_id)
  );

  id_ex_reg u_id_ex_reg (
    .clk(clk),
    .reset(reset),
    .flush_id_ex(flush_id_ex),
    .pc_id(pc_id),
    .pc_plus_4_id(pc_plus_4_id),
    .rs1_data_id(rs1_data_id),
    .rs2_data_id(rs2_data_id),
    .imm_id(imm_id),
    .rs1_addr_id(rs1_addr_id),
    .rs2_addr_id(rs2_addr_id),
    .rd_addr_id(rd_addr_id),
    .ctrl_id(ctrl_id),
    .pc_ex(pc_ex),
    .pc_plus_4_ex(pc_plus_4_ex),
    .rs1_data_ex(rs1_data_ex),
    .rs2_data_ex(rs2_data_ex),
    .imm_ex(imm_ex),
    .rs1_addr_ex(rs1_addr_ex),
    .rs2_addr_ex(rs2_addr_ex),
    .rd_addr_ex(rd_addr_ex),
    .ctrl_ex(ctrl_ex)
  );


  // --------------------------------------------------------------------------
  // 3. Execute (EX) Stage & Pipeline Register
  // --------------------------------------------------------------------------
  execute_stage u_execute_stage (
    .pc_ex(pc_ex),
    .rs1_data_ex(rs1_data_ex),
    .rs2_data_ex(rs2_data_ex),
    .imm_ex(imm_ex),
    .ctrl_ex(ctrl_ex),
    .forward_a(forward_a),
    .forward_b(forward_b),
    .alu_result_mem(alu_result_mem),
    .write_data_wb(write_data_wb),
    .alu_result_ex(alu_result_ex),
    .write_data_mem_ex(write_data_mem_ex),
    .branch_target_ex(branch_target_ex),
    .pcsrc_ex(pcsrc_ex)
  );

  ex_mem_reg u_ex_mem_reg (
    .clk(clk),
    .reset(reset),
    .pc_plus_4_ex(pc_plus_4_ex),
    .alu_result_ex(alu_result_ex),
    .write_data_mem_ex(write_data_mem_ex),
    .rd_addr_ex(rd_addr_ex),
    .ctrl_ex(ctrl_ex),
    .pc_plus_4_mem(pc_plus_4_mem),
    .alu_result_mem(alu_result_mem),
    .write_data_mem(write_data_mem),
    .rd_addr_mem(rd_addr_mem),
    .ctrl_mem(ctrl_mem)
  );


  // --------------------------------------------------------------------------
  // 4. Memory Access (MEM) Stage & Pipeline Register
  // --------------------------------------------------------------------------
  memory_stage u_memory_stage (
    .alu_result_mem(alu_result_mem),
    .write_data_mem(write_data_mem),
    .dmem_read_data_raw(dmem_rdata),
    .ctrl_mem(ctrl_mem),
    .dmem_addr(dmem_addr),
    .dmem_write_data(dmem_wdata),
    .dmem_byte_enable(dmem_byte_enable),
    .dmem_read_en(dmem_read_en),
    .dmem_write_en(dmem_write_en),
    .read_data_mem_formatted(read_data_mem_formatted)
  );

  mem_wb_reg u_mem_wb_reg (
    .clk(clk),
    .reset(reset),
    .pc_plus_4_mem(pc_plus_4_mem),
    .alu_result_mem(alu_result_mem),
    .read_data_mem_formatted(read_data_mem_formatted),
    .rd_addr_mem(rd_addr_mem),
    .ctrl_mem(ctrl_mem),
    .pc_plus_4_wb(pc_plus_4_wb),
    .alu_result_wb(alu_result_wb),
    .read_data_wb(read_data_wb),
    .rd_addr_wb(rd_addr_wb),
    .ctrl_wb(ctrl_wb)
  );


  // --------------------------------------------------------------------------
  // 5. Writeback (WB) Stage
  // --------------------------------------------------------------------------
  writeback_stage u_writeback_stage (
    .alu_result_wb(alu_result_wb),
    .read_data_wb(read_data_wb),
    .pc_plus_4_wb(pc_plus_4_wb),
    .ctrl_wb(ctrl_wb),
    .write_data_wb(write_data_wb)
  );


  // --------------------------------------------------------------------------
  // 6. Hazard & Forwarding Unit
  // --------------------------------------------------------------------------
  hazard_unit u_hazard_unit (
    .rs1_id(rs1_addr_id),
    .rs2_id(rs2_addr_id),
    .rs1_ex(rs1_addr_ex),
    .rs2_ex(rs2_addr_ex),
    .rd_ex(rd_addr_ex),
    .mem_read_ex(ctrl_ex.mem_read),
    .pcsrc_ex(pcsrc_ex),
    .rd_mem(rd_addr_mem),
    .reg_write_mem(ctrl_mem.reg_write),
    .rd_wb(rd_addr_wb),
    .reg_write_wb(ctrl_wb.reg_write),
    .forward_a(forward_a),
    .forward_b(forward_b),
    .stall_if(stall_if),
    .stall_id(stall_id),
    .flush_if_id(flush_if_id),
    .flush_id_ex(flush_id_ex)
  );

endmodule
