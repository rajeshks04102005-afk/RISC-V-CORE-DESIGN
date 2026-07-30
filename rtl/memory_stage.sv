// ============================================================================
// File: memory_stage.sv
// Description: Data Memory Access (MEM) Stage for 5-Stage RV32I Core
// ============================================================================

`timescale 1ns / 1ps

import rv32i_pkg::*;

module memory_stage (
  input  logic [31:0]      alu_result_mem,
  input  logic [31:0]      write_data_mem, // Data to be stored (from EX stage)
  input  logic [31:0]      dmem_read_data_raw, // Raw 32-bit read from Data Memory
  input  control_signals_t ctrl_mem,

  // Outputs to Data Memory
  output logic [31:0]      dmem_addr,
  output logic [31:0]      dmem_write_data,
  output logic [3:0]       dmem_byte_enable,
  output logic             dmem_read_en,
  output logic             dmem_write_en,

  // Read Data Output formatted for WB stage
  output logic [31:0]      read_data_mem_formatted
);

  assign dmem_addr     = alu_result_mem;
  assign dmem_read_en  = ctrl_mem.mem_read;
  assign dmem_write_en = ctrl_mem.mem_write;

  logic [1:0] byte_offset;
  assign byte_offset = alu_result_mem[1:0];

  // --------------------------------------------------------------------------
  // Store Alignment & Byte Enable Generation
  // --------------------------------------------------------------------------
  always_comb begin
    dmem_write_data  = 32'd0;
    dmem_byte_enable = 4'b0000;

    if (ctrl_mem.mem_write) begin
      case (ctrl_mem.mem_funct3)
        FUNCT3_SB: begin
          case (byte_offset)
            2'b00: begin dmem_write_data = {24'b0, write_data_mem[7:0]};        dmem_byte_enable = 4'b0001; end
            2'b01: begin dmem_write_data = {16'b0, write_data_mem[7:0], 8'b0};   dmem_byte_enable = 4'b0010; end
            2'b10: begin dmem_write_data = {8'b0,  write_data_mem[7:0], 16'b0};  dmem_byte_enable = 4'b0100; end
            2'b11: begin dmem_write_data = {write_data_mem[7:0], 24'b0};        dmem_byte_enable = 4'b1000; end
          endcase
        end

        FUNCT3_SH: begin
          case (byte_offset[1])
            1'b0:  begin dmem_write_data = {16'b0, write_data_mem[15:0]};       dmem_byte_enable = 4'b0011; end
            1'b1:  begin dmem_write_data = {write_data_mem[15:0], 16'b0};       dmem_byte_enable = 4'b1100; end
          endcase
        end

        FUNCT3_SW: begin
          dmem_write_data  = write_data_mem;
          dmem_byte_enable = 4'b1111;
        end

        default: begin
          dmem_write_data  = write_data_mem;
          dmem_byte_enable = 4'b1111;
        end
      endcase
    end
  end

  // --------------------------------------------------------------------------
  // Load Byte/Halfword/Word Extension Formatting
  // --------------------------------------------------------------------------
  always_comb begin
    read_data_mem_formatted = 32'd0;

    if (ctrl_mem.mem_read) begin
      case (ctrl_mem.mem_funct3)
        FUNCT3_LB: begin
          case (byte_offset)
            2'b00: read_data_mem_formatted = {{24{dmem_read_data_raw[7]}},   dmem_read_data_raw[7:0]};
            2'b01: read_data_mem_formatted = {{24{dmem_read_data_raw[15]}},  dmem_read_data_raw[15:8]};
            2'b10: read_data_mem_formatted = {{24{dmem_read_data_raw[23]}},  dmem_read_data_raw[23:16]};
            2'b11: read_data_mem_formatted = {{24{dmem_read_data_raw[31]}},  dmem_read_data_raw[31:24]};
          endcase
        end

        FUNCT3_LBU: begin
          case (byte_offset)
            2'b00: read_data_mem_formatted = {24'b0, dmem_read_data_raw[7:0]};
            2'b01: read_data_mem_formatted = {24'b0, dmem_read_data_raw[15:8]};
            2'b10: read_data_mem_formatted = {24'b0, dmem_read_data_raw[23:16]};
            2'b11: read_data_mem_formatted = {24'b0, dmem_read_data_raw[31:24]};
          endcase
        end

        FUNCT3_LH: begin
          case (byte_offset[1])
            1'b0: read_data_mem_formatted = {{16{dmem_read_data_raw[15]}}, dmem_read_data_raw[15:0]};
            1'b1: read_data_mem_formatted = {{16{dmem_read_data_raw[31]}}, dmem_read_data_raw[31:16]};
          endcase
        end

        FUNCT3_LHU: begin
          case (byte_offset[1])
            1'b0: read_data_mem_formatted = {16'b0, dmem_read_data_raw[15:0]};
            1'b1: read_data_mem_formatted = {16'b0, dmem_read_data_raw[31:16]};
          endcase
        end

        FUNCT3_LW: begin
          read_data_mem_formatted = dmem_read_data_raw;
        end

        default: begin
          read_data_mem_formatted = dmem_read_data_raw;
        end
      endcase
    end
  end

endmodule
