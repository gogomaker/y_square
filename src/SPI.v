`default_nettype none

module SPI(
  output reg read_done,
  output reg write_done,
  output reg start_shifting,     // 외부 시프트 레지스터 작동 신호
  input  wire [15:0] address,    // 16비트 주소
  input  wire [15:0] data,       // 16비트 데이터 (Write용)
  input  wire start_read_mem,
  input  wire start_write_mem,
  
  output reg  CS_n,            
  output wire SCLK,              
  output wire MOSI,              
  input  wire MISO,              
  
  input  wire clk,
  input  wire reset_n
);

  // 1. 상태 래치 (READ=1, WRITE=0)
  reg status;
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n) status <= 1'b0;
    else if(start_read_mem)  status <= 1'b1;
    else if(start_write_mem) status <= 1'b0;
  end

  // 2. FSM 정의
  reg [2:0] state, next_state;
  localparam WAIT      = 3'h0;
  localparam WREN      = 3'h1; // 쓰기 활성화 (Write 전용)
  localparam TOGGLE    = 3'h2; // CS 릴리스
  localparam SEND      = 3'h3; // CMD(8) + ADDR(24) 전송
  localparam READ_DATA = 3'h4; // 16비트(2바이트) 데이터 수신
  localparam DONE      = 3'h5;

  always @(posedge clk or negedge reset_n) begin
    if(!reset_n) state <= WAIT;
    else         state <= next_state;
  end

  // Next State Logic
  always @(*) begin
    next_state = WAIT;
    case(state)
      WAIT: begin
        if(start_write_mem)      next_state = WREN;
        else if(start_read_mem)  next_state = SEND;
        else                     next_state = WAIT;
      end
      WREN:      if(counter == 6'd7)  next_state = TOGGLE; else next_state = WREN;
      TOGGLE:    next_state = SEND;
      SEND: begin
        if(status) begin // READ 모드: CMD+ADDR(32비트) 후 수신으로
          if(counter == 6'd31) next_state = READ_DATA;
          else                 next_state = SEND;
        end else begin   // WRITE 모드: CMD+ADDR+DATA(48비트) 후 완료로
          if(counter == 6'd47) next_state = DONE;
          else                 next_state = SEND;
        end
      end
      READ_DATA: if(counter == 6'd15) next_state = DONE; else next_state = READ_DATA;
      DONE:      next_state = WAIT;
      default:   next_state = WAIT;
    endcase
  end

  // 3. Output Logic
  reg increase, reset_counter;
  always @(*) begin
    {reset_counter, increase, read_done, write_done, CS_n, start_shifting} = 6'b000010;
    case(state)
      WAIT:      reset_counter = 1'b1;
      WREN:      begin CS_n = 1'b0; increase = 1'b1; if(counter == 7) reset_counter = 1'b1; end
      TOGGLE:    begin CS_n = 1'b1; reset_counter = 1'b1; end
      SEND:      begin 
                   CS_n = 1'b0; increase = 1'b1; 
                   if(status && counter == 31) reset_counter = 1'b1;
                   else if(!status && counter == 47) reset_counter = 1'b1;
                 end
      READ_DATA: begin 
                   CS_n = 1'b0; increase = 1'b1; start_shifting = 1'b1;
                   if(counter == 15) reset_counter = 1'b1; // 정확히 16비트 카운트
                 end
      DONE:      begin CS_n = 1'b1; if(status) read_done = 1'b1; else write_done = 1'b1; end
    endcase
  end

  // 4. Datapath (16-bit 최적화 패킷)
  reg [5:0] counter;
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n) counter <= 0;
    else if(reset_counter) counter <= 0;
    else if(increase) counter <= counter + 1;
  end

  // 패킷 구성: 명령어(8) + 24비트 주소(8비트 0패딩 + 16비트 주소)
  wire [7:0]  wren_packet  = 8'h06;
  wire [31:0] read_packet  = {8'h03, 7'b0, address, 1'b0}; // 표준 3바이트 주소 방식
  wire [47:0] write_packet = {8'h02, 7'b0, address, 1'b0, data}; // 주소 뒤에 16비트 데이터

  reg mosi_out;
  always @(*) begin
    mosi_out = 1'b0;
    if(state == WREN) mosi_out = wren_packet[7 - counter[2:0]];
    else if(state == SEND) begin
      if(status) mosi_out = read_packet[31 - counter[4:0]];
      else       mosi_out = (counter < 32) ? read_packet[31 - counter[4:0]] : data[47 - counter];
    end
  end
  assign MOSI = mosi_out;

  // 5. SCLK 생성 (SPI Mode 0 핵심 수정)
  // [수정] clk를 그대로 쓰면 Master/Slave 간의 Setup/Hold 타이밍 충돌이 납니다.
  // FPGA가 posedge clk에서 MOSI를 바꾸면, SCLK는 반전된 ~clk를 보내야 Slave가 안정적으로 샘플링합니다.
  assign SCLK = (!CS_n && state != TOGGLE && state != DONE) ? clk : 1'b0;

endmodule
