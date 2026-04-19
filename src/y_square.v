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
  input  wire       ena,      // always 1 when the design is powered
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // 1. 내부 와이어 선언
  wire [15:0] cpu_addr, cpu_data_out, cpu_data_in;
  wire cpu_start_read, cpu_start_write;
  wire spi_en, din_en, dout_en, uart_rx_en, uart_tx_en;
  wire [15:0] io_data_in;
  wire read_done, write_done;

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
    .done_read(read_done),
    .done_write(write_done),
    .clk(clk),
    .reset_n(rst_n),
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
    .data_memory_in(cpu_data_in),
    .start_read_mem(cpu_start_read),
    .start_write_mem(cpu_start_write),
    .read_done(read_done),
    .write_done(write_done),
    .parallel_out_shifter(parallel_out_shifter),
    .start_shifting(shifting_CPU),
    .direction(direction_of_CPU),
    .sr_parallel_load(sr_parallel_load),
    .sel_sr(sel_sr),
    .clk(clk),
    .reset_n(rst_n)
  );
  
  // 4. SPI 모듈 (정상적인 인스턴스화 및 start_shifting 연결)
  SPI spi_inst (
    .address(cpu_addr),
    .data(cpu_data_out),
    .start_read_mem(cpu_start_read & spi_en),
    .start_write_mem(cpu_start_write & spi_en),
    .start_shifting(shifting_SPI), // <--- 이 포트가 정확히 연결됨
    .read_done(read_done_spi),
    .write_done(write_done_spi),
    .CS_n(uio_out[4]),
    .SCLK(uio_out[5]),
    .MOSI(uio_out[6]),
    .MISO(uio_in[7]),
    .clk(clk),
    .reset_n(rst_n)
  );
  
  // 5. IO 모듈 (Digital In/Out)
  IO io_inst (
    .clk(clk),
    .reset_n(rst_n),
    .write_data(cpu_data_out),
    .read_data(io_data_in),
    .din_en(din_en),
    .dout_en(dout_en),
    .start_write(cpu_start_write),
    .phys_in(ui_in),
    .phys_out(uo_out)
  );

  // 6. 읽기 데이터 경로 MUX (수정: spi_data_in 대신 sr_parallel_out 사용)
  reg spi_en_pipelined, din_en_pipelined;
  always @(posedge clk, negedge rst_n) begin
    if(!rst_n) begin
      spi_en_pipelined <= 1'b0;
      din_en_pipelined <= 1'b0;
    end else begin
      spi_en_pipelined <= spi_en;
      din_en_pipelined <= din_en;
    end
  end
  assign cpu_data_in = (din_en | din_en_pipelined) ? io_data_in : sr_parallel_out;

  // 7. 완료 신호 통합
  assign read_done  = (spi_en) ? read_done_spi  : 1'b1;
  assign write_done = (spi_en) ? write_done_spi : 1'b1;

  // 8. 시프트 레지스터 (공용 리소스)
  shifter s(
    .answer(sr_parallel_out),
    .parallel_in(parallel_out_shifter),
    .serial_in(sel_sr ? 1'b0 : uio_in[7]),
    .en_shift(sel_sr ? shifting_CPU : shifting_SPI),
    .en_load(sel_sr ? sr_parallel_load : 1'b0),
    .direction(sel_sr ? direction_of_CPU : 1'b1),
    .clk(clk),
    .reset_n(rst_n)
  );

  // 9. Tiny Tapeout 핀 설정 및 경고 방지
  wire unused;
  assign unused = ena | &uio_in; // 사용하지 않는 신호 묶음
  assign uio_out[3:0] = 4'h0;
  assign uio_out[7] = 1'b0;
  // 핀 방향 설정 (CS, SCLK, MOSI 등 출력 비트 확인)
  assign uio_oe = 8'b01110010; 

endmodule
