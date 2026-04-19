`default_nettype none

module address_decoder(
  input wire [15:0] address,
  input wire start_read,
  input wire start_write,
  input wire done_read,
  input wire done_write,
  input wire clk,
  input wire reset_n,

  // 각 모듈을 깨우는 활성화(Enable) 신호
  output wire spi_en,
  output wire din_en,
  output wire dout_en,
  output wire uart_rx_en,
  output wire uart_tx_en
);

  // CPU가 무언가 읽거나 쓰려고 할 때만 디코딩 시작
  reg while_mem_access;
  always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
      while_mem_access <= 1'b0;
    else begin
      if(start_read | start_write)
        while_mem_access <= 1'b1;
      else if(done_read | done_write)
        while_mem_access <= 1'b0;
    end
  end
  wire mem_access = while_mem_access | start_read | start_write;
  // 1. 하위 I/O 영역 판단 (0x0000 ~ 0x000F)
  // 상위 11비트(15~5)가 모두 0이면 I/O 영역입니다.
  wire is_mem_range = |address[15:4];

  // 2. 장치별 상세 디코딩 (비트 4와 3을 이용한 MUX 구조)
  // 00xxx (0x00~0x07): Digital In
  assign din_en     = mem_access & !is_mem_range & (address[1:0] == 2'b00);
  
  // 01xxx (0x08~0x0F): Digital Out
  assign dout_en    = mem_access & !is_mem_range & (address[1:0] == 2'b01);
  
  // 10xxx (0x10~0x17): UART RX
  assign uart_rx_en = mem_access & !is_mem_range & (address[1:0] == 2'b10);
  
  // 11xxx (0x18~0x1F): UART TX
  assign uart_tx_en = mem_access & !is_mem_range & (address[1:0] == 2'b11);

  // 3. SPI FRAM 영역 (0x0020 이상 모든 주소)
  // I/O 영역이 아니면 모두 메모리 접근으로 간주합니다.
  assign spi_en     = mem_access & is_mem_range;

endmodule
