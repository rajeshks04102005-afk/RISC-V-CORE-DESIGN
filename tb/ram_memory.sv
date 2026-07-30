// ============================================================================
// File: ram_memory.sv
// Description: Dual-Port RAM Module for Instruction and Data Memory
// ============================================================================

`timescale 1ns / 1ps

module ram_memory #(
  parameter int MEM_DEPTH_WORDS = 4096, // 16 KB Memory
  parameter string HEX_FILE     = "imem.hex"
)(
  input  logic        clk,
  input  logic        reset,

  // Instruction Memory Port (Read-only)
  input  logic [31:0] imem_addr,
  output logic [31:0] imem_rdata,

  // Data Memory Port (Read/Write)
  input  logic [31:0] dmem_addr,
  input  logic [31:0] dmem_wdata,
  input  logic [3:0]  dmem_byte_enable,
  input  logic        dmem_read_en,
  input  logic        dmem_write_en,
  output logic [31:0] dmem_rdata
);

  // 32-bit word memory array
  logic [31:0] mem [0:MEM_DEPTH_WORDS-1];

  integer i;

  // Initialize memory with zeros and load hex file if present
  initial begin
    for (i = 0; i < MEM_DEPTH_WORDS; i = i + 1) begin
      mem[i] = 32'd0;
    end
    if (HEX_FILE != "") begin
      $readmemh(HEX_FILE, mem);
    end
  end

  // Instruction Memory Read (Word aligned)
  // Shift address by 2 to convert byte address to word index
  wire [29:0] imem_word_addr = imem_addr[31:2];
  assign imem_rdata = (imem_word_addr < MEM_DEPTH_WORDS) ? mem[imem_word_addr] : 32'd0;

  // Data Memory Read (Word aligned)
  wire [29:0] dmem_word_addr = dmem_addr[31:2];
  assign dmem_rdata = (dmem_read_en && (dmem_word_addr < MEM_DEPTH_WORDS)) ? mem[dmem_word_addr] : 32'd0;

  // Data Memory Write with Byte Enables
  always_ff @(posedge clk) begin
    if (dmem_write_en && (dmem_word_addr < MEM_DEPTH_WORDS)) begin
      if (dmem_byte_enable[0]) mem[dmem_word_addr][7:0]   <= dmem_wdata[7:0];
      if (dmem_byte_enable[1]) mem[dmem_word_addr][15:8]  <= dmem_wdata[15:8];
      if (dmem_byte_enable[2]) mem[dmem_word_addr][23:16] <= dmem_wdata[23:16];
      if (dmem_byte_enable[3]) mem[dmem_word_addr][31:24] <= dmem_wdata[31:24];
    end
  end

endmodule
