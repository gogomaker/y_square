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

  // 1. 내부 와이어 선언
  wire [15:0] cpu_addr, cpu_data_out, cpu_data_in;
  wire cpu_start_read, cpu_start_write;
  wire spi_en, din_en, dout_en, uart_rx_en, uart_tx_en;
  wire [15:0] spi_data_in, io_data_in;
  wire read_done, write_done;

  // Additional wire declarations
  wire [15:0] parallel_out_shifter;
  wire shifting_CPU, direction_of_CPU, sr_parallel_load, sel_sr;
  wire [15:0] sr_parallel_out;
  wire shifting_SPI;
  wire read_done_spi, write_done_spi;

  // 2. Address Decoder (교통정리)
  address_decoder decoder (
    .address(cpu_addr),
    .start_read(cpu_start_read),
    .start_write(cpu_start_write),
    .spi_en(spi_en),
    .din_en(din_en),
    .dout_en(dout_en),
    .uart_rx_en(uart_rx_en),
    .uart_tx_en(uart_tx_en)
  );
  
  // 3. CPU 인스턴스화
  CPU cpu_inst (
    .address_memory(cpu_addr),
    .data_memory_out(cpu_data_out),
    .data_memory_in(cpu_data_in), // 아래 MUX 결과가 들어감
    .start_read_mem(cpu_start_read),
    .start_write_mem(cpu_start_write),
    .read_done(read_done),
    .write_done(write_done),
    // ... (shifter 관련 포트 연결) ...
    .parallel_out_shifter(parallel_out_shifter),
    .start_shifting(shifting_CPU),
    .direction(direction_of_CPU),
    .sr_parallel_load(sr_parallel_load),
    .sel_sr(sel_sr),
    .clk(clk),
    .reset_n(rst_n)
  );
  
  // 4. SPI 모듈 (Enable 신호로 Gating)
  SPI spi_inst (
    .address(cpu_addr),
    .data(cpu_data_out),
    .start_read_mem(cpu_start_read & spi_en),   // SPI 영역일 때만 시작
    .start_write_mem(cpu_start_write & spi_en), // SPI 영역일 때만 시작
    .start_shifting(shifting_SPI),
    .read_done(read_done_spi),
    .write_done(write_done_spi),
    .CS_n(uio_out[2]), .SCLK(uio_out[3]), .MOSI(uio_out[4]), .MISO(uio_in[5]),
    .clk(clk), .reset_n(rst_n)
  );
  
  // 5. IO 모듈 (Digital In/Out)
  IO io_inst (
    .clk(clk), .reset_n(rst_n),
    .write_data(cpu_data_out),
    .read_data(io_data_in),
    .din_en(din_en),
    .dout_en(dout_en),
    .start_write(cpu_start_write),
    .phys_in(ui_in), .phys_out(uo_out)
  );
  // 6. 읽기 데이터 경로 MUX (매우 중요!)
  // CPU가 데이터를 읽을 때, 주소에 따라 누구의 데이터를 줄지 결정합니다.
  assign cpu_data_in = (spi_en) ? spi_data_in : 
                       (din_en) ? io_data_in  : 16'h0000;

  // 7. 완료 신호 통합
  // 장치가 여러 개이므로, 현재 활성화된 장치의 완료 신호를 CPU에 전달합니다.
  assign read_done  = (spi_en) ? read_done_spi : 1'b1; // IO는 즉시 완료되므로 1
  assign write_done = (spi_en) ? write_done_spi : 1'b1;

  shifter s(
    .answer(sr_parallel_out),
    .parallel_in(parallel_out_shifter),
    .serial_in(uio_in[5]),
    .en_shift(sel_sr ? shifting_CPU : shifting_SPI),
    .en_load(sel_sr ? sr_parallel_load : 1'b0),     // 병렬 로딩 활성화 신호
    .direction(sel_sr ? direction_of_CPU : 1'b1),   // 1: Left, 0: Right
    .clk(clk),
    .reset_n(rst_n)
  );
  //this is for just test.
  wire unused;
  assign unused = ena | &uio_in;
  assign uio_out[7:6] = 2'b0;
  assign uio_out[4:0] = 5'b0;
  assign uio_oe = 8'b11011110;
endmodule
