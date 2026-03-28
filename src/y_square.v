/*
 * Copyright (c) 2026 Caleb Son
 * SPDX-License-Identifier: Apache-2.0
 */

`timescale 1ns/1ps
`default_nettype none

module tt_um_ysquare (
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  CPU cpu(
    .address_memory(),
    .data_memory_in(),
    .data_memory_out(),
    .parallel_out_shifter(),
    .shamt(),
    .direction(),
    .sel_sr(),
    //memory control signal port
    .start_read_mem(),
    .start_write_mem(),
    .read_done(),
    .write_done(),
    //system port
    .clk(clk),
    .reset_n(rst_n)
  );

  shifter s(
    .answer(),
    .done(),
    .shamt(),
    .parallel_in(),
    .serial_in(),
    .start(),
    .direction(),  //0이 right, 1이 left
    .clk(clk),
    .reset_n(rst_n)
  );
  
  wire unused;
  assign unused = ena;

endmodule
