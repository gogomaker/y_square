`default_nettype none

module SPI(
  // CPU 컨트롤러와의 인터페이스
  output reg read_done,
  output reg write_done,
  output reg start_shifting,     // 외부 시프트 레지스터 작동 신호 (READ 시)
  input  wire [15:0] address,    // CPU의 16비트 메모리 주소
  input  wire [15:0] data,       // CPU에서 메모리로 쓸 16비트 데이터
  input  wire start_read_mem,
  input  wire start_write_mem,
  
  // 외부 SPI 물리 핀 (메모리와 연결)
  output reg  CS_n,              // Active LOW Chip Select
  output wire SCLK,              // SPI Clock
  output wire MOSI,              // Master Out Slave In
  input  wire MISO,              // Master In Slave Out (외부 시프터가 직접 받을 수도 있음)
  
  // 시스템 신호
  input  wire clk,
  input  wire reset_n
);

  // =========================================================
  // 1. 동작 Status 래치 (1: READ, 0: WRITE)
  // =========================================================
  reg status;
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
      status <= 1'b0;
    else if(start_read_mem)
      status <= 1'b1;
    else if(start_write_mem)
      status <= 1'b0;
  end

  // =========================================================
  // 2. FSM (상태 머신) 정의
  // =========================================================
  reg [2:0] state, next_state;
  
  localparam WAIT      = 3'h0;
  localparam WREN      = 3'h1; // 쓰기 보호 해제 명령 전송 (0x06)
  localparam TOGGLE    = 3'h2; // CS 핀 토글 (WREN 인식용)
  localparam SEND      = 3'h3; // OPcode + 주소 (+ WRITE시 데이터까지) 전송
  localparam READ_DATA = 3'h4; // 메모리로부터 데이터 수신
  localparam DONE      = 3'h5; // 완료 플래그 발생

  // State Register
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n) state <= WAIT;
    else         state <= next_state;
  end

  // Next State Logic
  always @(*) begin
    case(state)
      WAIT: begin
        if(start_write_mem)      next_state = WREN;
        else if(start_read_mem)  next_state = SEND;
        else                     next_state = WAIT;
      end
          
      WREN: begin
        if(counter == 6'd7)      next_state = TOGGLE;
        else                     next_state = WREN;
      end
          
      TOGGLE: begin
        next_state = SEND;
      end
          
      SEND: begin
        if(status) begin // READ
          if(counter == 6'd31)   next_state = READ_DATA;
          else                   next_state = SEND;
        end else begin   // WRITE
          if(counter == 6'd47)   next_state = DONE;
          else                   next_state = SEND;
        end
      end
          
      READ_DATA: begin
        if(counter == 6'd15)     next_state = DONE;
        else                     next_state = READ_DATA;
      end
          
      DONE: begin
        next_state = WAIT;
      end
          
      default:                     next_state = WAIT;
    endcase
  end

  // =========================================================
  // 3. FSM Output Logic & Counter Control
  // =========================================================
  reg increase;
  reg reset_counter;

  always @(*) begin
    // 래치 방지를 위한 초기값 선언
    reset_counter  = 1'b0;
    increase       = 1'b0;
    read_done      = 1'b0;
    write_done     = 1'b0;
    CS_n           = 1'b1;
    start_shifting = 1'b0;

    case(state)
      WAIT: begin
        reset_counter = 1'b1; // 대기 중에는 카운터 0으로 유지
      end
      
      WREN: begin
        CS_n = 1'b0;
        increase = 1'b1;
        if(counter == 6'd7) reset_counter = 1'b1; // 다음 상태를 위해 리셋
      end
      
      TOGGLE: begin
        CS_n = 1'b1; // CS 핀을 1로 올려서 WREN명령 확정
        reset_counter = 1'b1;
      end
      
      SEND: begin
        CS_n = 1'b0;
        increase = 1'b1;
        if(status && counter == 6'd31)        reset_counter = 1'b1;
        else if(!status && counter == 6'd47)  reset_counter = 1'b1;
      end
      
      READ_DATA: begin
        CS_n = 1'b0;
        increase = 1'b1;
        start_shifting = 1'b1; // 외부 시프트 레지스터 16번 작동 지시!
        if(counter == 6'd15) reset_counter = 1'b1;
      end
      
      DONE: begin
        CS_n = 1'b1;
        if(status) read_done  = 1'b1;
        else       write_done = 1'b1;
        reset_counter = 1'b1;
      end
      default: begin
        reset_counter  = 1'b0;
        increase       = 1'b0;
        read_done      = 1'b0;
        write_done     = 1'b0;
        CS_n           = 1'b1;
        start_shifting = 1'b0;
      end
    endcase
  end

  // =========================================================
  // 4. Datapath: 카운터 및 MUXing (핵심 로직)
  // =========================================================
  reg [5:0] counter; // 최대 47까지 세어야 하므로 6비트 필요
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n || reset_counter)
      counter <= 6'd0;
    else if(increase)
      counter <= counter + 6'd1;
  end

  // 가상의 패킷 버퍼 (플립플롭을 전혀 사용하지 않는 단순 선 연결)
  wire [7:0]  wren_packet  = 8'h06;
  wire [31:0] read_packet  = {8'h03, 7'b0, address, 1'b0};
  wire [47:0] write_packet = {8'h02, 7'b0, address, 1'b0, data};

  // MUX를 통한 1비트 직렬 출력 (MOSI)
  reg mosi_out;
  always @(*) begin
    mosi_out = 1'b0; // Default
    if(state == WREN) begin
      mosi_out = wren_packet[3'd7 - counter[2:0]];
    end
    else if(state == SEND) begin
      if(status) // READ 모드
        mosi_out = read_packet[5'd31 - counter[4:0]];
      else       // WRITE 모드
        mosi_out = write_packet[6'd47 - counter[5:0]];
    end
  end
  assign MOSI = mosi_out;

  // =========================================================
  // 5. SPI Clock (SCLK) 생성 (SPI Mode 0)
  // =========================================================
  // 통신 중(CS_n == 0)일 때, 클록의 반전을 SCLK로 사용. 
  // 이렇게 하면 MOSI는 하강 에지에서 변하고, 메모리는 상승 에지에서 캡처함.
  assign SCLK = (!CS_n && state != TOGGLE && state != DONE) ? ~clk : 1'b0;

endmodule
