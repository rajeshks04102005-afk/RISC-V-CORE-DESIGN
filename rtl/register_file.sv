// ============================================================================
// File: register_file.sv
// Description: Dual-Read, Single-Write Register File (x0..x31) for RV32I Core
// ============================================================================

`timescale 1ns / 1ps

module register_file (
  input  logic        clk,
  input  logic        reset,
  input  logic        reg_write_wb,  // Write Enable from WB Stage
  input  logic [4:0]  rs1_addr,      // Source Register 1 Address
  input  logic [4:0]  rs2_addr,      // Source Register 2 Address
  input  logic [4:0]  rd_addr_wb,    // Destination Register Address
  input  logic [31:0] write_data_wb, // Data to write
  output logic [31:0] rs1_data,      // Read Data 1
  output logic [31:0] rs2_data       // Read Data 2
);

  // 32 registers of 32-bit width
  logic [31:0] registers [0:31];

  integer i;

  // Asynchronous Read with Register 0 hardwired to 0
  // Internal forwarding: If writing and reading the same register in WB cycle
  assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 :
                    ((rs1_addr == rd_addr_wb) && reg_write_wb) ? write_data_wb :
                    registers[rs1_addr];

  assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 :
                    ((rs2_addr == rd_addr_wb) && reg_write_wb) ? write_data_wb :
                    registers[rs2_addr];

  // Synchronous Write on posedge clk
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i < 32; i = i + 1) begin
        registers[i] <= 32'd0;
      end
    end else if (reg_write_wb && (rd_addr_wb != 5'd0)) begin
      registers[rd_addr_wb] <= write_data_wb;
    end
  end

endmodule
