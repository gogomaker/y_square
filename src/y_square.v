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

  wire start_read_mem, start_write_mem, read_done, write_done, sel_sr;
  wire direction_of_CPU, shifting_CPU, shifting_SPI, sr_parallel_loading;
  wire [15:0] address, data_for_spi, sr_parallel_out, parallel_out_shifter;
  CPU cpu(
    .address_memory(address),
    .data_memory_in(sr_parallel_out),
    .data_memory_out(data_for_spi),
    .parallel_out_shifter(parallel_out_shifter),
    .start_shifting(shifting_CPU),
    .direction(direction_of_CPU),
    .sr_parallel_loading(sr_parallel_loading),
    .sel_sr(sel_sr),
    //memory control signal port
    .start_read_mem(start_read_mem),
    .start_write_mem(start_write_mem),
    .read_done(read_done),
    .write_done(write_done),
    //system port
    .clk(clk),
    .reset_n(rst_n)
  );

  module SPI(
    // CPU 컨트롤러와의 인터페이스
    .address(address),
    .data(data_for_spi),
    .start_read_mem(start_read_mem),
    .start_write_mem(start_write_mem),
    .read_done(read_done),
    .write_done(write_done),
    .start_shifting(shifting_SPI),
    // 외부 SPI 물리 핀 (메모리와 연결)
    .CS_n(uio_out[2]),  // Active LOW Chip Select
    .SCLK(uio_out[3]),  // SPI Clock
    .MOSI(uio_out[4]),  // Master Out Slave In
    .MISO(uio_in[5]),   // Master In Slave Out (외부 시프터가 직접 받을 수도 있음)
    // 시스템 신호
    .clk(clk),
    .reset_n(reset_n)
  );

  shifter s(
    .answer(sr_parallel_out),
    .parallel_in(parallel_out_shifter),
    .serial_in(uio_in[5]),
    .en_shift(sel_sr ? shifting_CPU : shifting_SPI),
    .en_load(sel_sr ? sr_parallel_loading : 1'b0),     // 병렬 로딩 활성화 신호
    .direction(sel_sr ? direction_of_CPU : 1'b1),   // 1: Left, 0: Right
    .clk(clk),
    .reset_n(reset_n)
  );

  wire unused;
  assign unused = ena;
  assign uio_oe = 8'b11011110;
endmodule
