// ============================================================================
// File: fetch_stage.sv
// Description: Instruction Fetch (IF) Stage for 5-Stage RV32I RISC-V Core
// ============================================================================

`timescale 1ns / 1ps

module fetch_stage (
  input  logic        clk,
  input  logic        reset,
  input  logic        stall_if,       // Stall signal from Hazard Unit
  input  logic        pcsrc,          // Branch/Jump taken signal (1 = target, 0 = PC+4)
  input  logic [31:0] branch_target,  // Calculated target address from EX stage
  output logic [31:0] pc_if,          // Current Program Counter to IF/ID reg
  output logic [31:0] pc_plus_4_if,   // PC + 4 to IF/ID reg
  output logic [31:0] imem_addr       // Address to Instruction Memory
);

  logic [31:0] pc_reg;
  logic [31:0] next_pc;

  // Next PC MUX (Branch target vs Sequential PC+4)
  assign pc_plus_4_if = pc_reg + 32'd4;
  assign next_pc      = pcsrc ? branch_target : pc_plus_4_if;

  // Program Counter Synchronous Register
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      pc_reg <= 32'h0000_0000;
    end else if (!stall_if) begin
      pc_reg <= next_pc;
    end
  end

  assign pc_if     = pc_reg;
  assign imem_addr = pc_reg;

endmodule
