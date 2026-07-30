// ============================================================================
// File: tb_rv32i_core.sv
// Description: Testbench for 5-Stage RV32I Core with RAM Memory
// ============================================================================

`timescale 1ns / 1ps

module tb_rv32i_core;

  logic        clk;
  logic        reset;

  // Interconnect Wires
  logic [31:0] imem_addr;
  logic [31:0] imem_rdata;
  logic [31:0] dmem_addr;
  logic [31:0] dmem_wdata;
  logic [3:0]  dmem_byte_enable;
  logic        dmem_read_en;
  logic        dmem_write_en;
  logic [31:0] dmem_rdata;

  // Clock Generation (100 MHz clock, 10ns period)
  always #5 clk = ~clk;

  // Top-Level Core Instantiation
  rv32i_core u_rv32i_core (
    .clk(clk),
    .reset(reset),
    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_byte_enable(dmem_byte_enable),
    .dmem_read_en(dmem_read_en),
    .dmem_write_en(dmem_write_en),
    .dmem_rdata(dmem_rdata)
  );

  // RAM Memory Instantiation
  ram_memory #(
    .MEM_DEPTH_WORDS(4096),
    .HEX_FILE("imem.hex")
  ) u_ram_memory (
    .clk(clk),
    .reset(reset),
    .imem_addr(imem_addr),
    .imem_rdata(imem_rdata),
    .dmem_addr(dmem_addr),
    .dmem_wdata(dmem_wdata),
    .dmem_byte_enable(dmem_byte_enable),
    .dmem_read_en(dmem_read_en),
    .dmem_write_en(dmem_write_en),
    .dmem_rdata(dmem_rdata)
  );

  // Simulation Sequence
  initial begin
    // Waveform Dump Setup for GTKWave / Vivado
    $dumpfile("waveform.vcd");
    $dumpvars(0, tb_rv32i_core);

    clk   = 1'b0;
    reset = 1'b1;

    #20;
    reset = 1'b0;

    $display("=========================================================");
    $display("   Starting 5-Stage RV32I Core Simulation");
    $display("=========================================================");

    // Run simulation for 200 cycles
    #2000;

    $display("=========================================================");
    $display("   Simulation Complete");
    $display("   Register x1  = 0x%h", u_rv32i_core.u_decode_stage.u_register_file.registers[1]);
    $display("   Register x2  = 0x%h", u_rv32i_core.u_decode_stage.u_register_file.registers[2]);
    $display("   Register x3  = 0x%h", u_rv32i_core.u_decode_stage.u_register_file.registers[3]);
    $display("   Register x4  = 0x%h", u_rv32i_core.u_decode_stage.u_register_file.registers[4]);
    $display("   Register x5  = 0x%h", u_rv32i_core.u_decode_stage.u_register_file.registers[5]);
    $display("   Register x10 = 0x%h", u_rv32i_core.u_decode_stage.u_register_file.registers[10]);
    $display("=========================================================");

    $finish;
  end

endmodule
