`default_nettype none

module cpu_controller(
  output reg sel_address,
  output reg sel_PCconst,
  output reg sel_write,
  output reg sel_A,
  output reg [1:0] sel_B,
  output reg sel_sr,
  output reg EN_pc,
  output reg EN_ir,
  output reg EN_rf,
  output reg start_read_mem,
  output reg start_write_mem,
  output reg start_shifting,
  output reg sr_parallel_load,  // [추가] 시프터 병렬 로드 신호
  input wire [3:0] shamt,
  input wire [3:0] OPcode,
  input wire [1:0] func,
  input wire zero_flag,
  input wire read_done,
  input wire write_done,
  input wire clk,
  input wire reset_n
);

  // define state
  reg [3:0] state, next_state;
  localparam START  = 4'h0;  // reset state
  localparam WATM1  = 4'h1;  // wait memory latency state 1
  localparam PC_UP  = 4'h2;  // PC increase state
  localparam READY  = 4'h3;  // wait for datapath state
  localparam SHIFT  = 4'h4;  // for SLR, SLL state 
  localparam WRTRF  = 4'h5;  // write register file state
  localparam PCRDY  = 4'h6;  // PC ready state, for load constant value
  localparam LRWRT  = 4'h7;  // Link register write state
  localparam PCWRT  = 4'h8;  // PC write state
  localparam WRTMM  = 4'h9;  // Read memory start state
  localparam WATM2  = 4'hA;  // wait memory latency state 2
  localparam READM  = 4'hB;  // write memory start state
  localparam WATM3  = 4'hC;  // wait memory latency state 3
  localparam WMTRF  = 4'hD;  // write memory to register file
  localparam LOADSR = 4'hE;  // [추가] Load Shift Register state
  
  // define current state
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
      state <= START;
    else
      state <= next_state;
  end

  // define next state
  always @(*) begin
    next_state = START;
    case(state)
      START: next_state = WATM1;
      WATM1: next_state = (read_done) ? PC_UP : WATM1;
      PC_UP: next_state = READY;
      READY: begin
        if(OPcode[3:1] == 3'b100)
          // [수정] SHIFT로 바로 가지 않고 LOADSR로 먼저 이동
          next_state = (func == 2'b11) ? LOADSR : WRTRF; 
        else if(OPcode[3] == 1'b0 & (OPcode[2] == 1'b0 | OPcode[1] == 1'b0))
          next_state = WRTRF;
        else if(OPcode[3:1] == 3'b011)
          next_state = PCRDY;
        else if(OPcode == 4'b1010)
          next_state = LRWRT;
        else if(OPcode == 4'b1011)
          next_state = PCWRT;
        else if(OPcode[3:1] == 3'b111)
          next_state = WRTMM;
        else if(OPcode[3:1] == 3'b110)
          next_state = READM;
        else
          next_state = START;
      end
      // [추가] LOADSR 상태 다음에는 SHIFT로 이동
      LOADSR: next_state = SHIFT;
      SHIFT:  next_state = (shamt == 4'h0 || shift_counter == shamt - 4'h1) ? WRTRF : SHIFT;
      WRTRF:  next_state = START;
      PCRDY:  next_state = START;
      LRWRT:  next_state = START;
      PCWRT:  next_state = START;
      WRTMM:  next_state = (write_done) ? START : WRTMM;
      READM:  next_state = (read_done) ? WMTRF : READM;
      WMTRF:  next_state = START;
      default: next_state = START;
    endcase
  end

  // ---------------------------------------------------------
  // 시프트 연산을 위한 4비트 카운터
  // ---------------------------------------------------------
  reg [3:0] shift_counter;
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
      shift_counter <= 4'h0;
    else if(state == SHIFT)
      shift_counter <= shift_counter + 4'h1;
    else
      shift_counter <= 4'h0; // SHIFT 상태가 아니면 항상 0으로 리셋
  end

  wire [1:0] selected_B = (OPcode[3:1] == 3'b100) ? 2'd0 : (OPcode[3:1] == 3'b101) ? 2'd3 : 2'd1;
  // define current output
  always @(*) begin
    {sr_parallel_load, start_shifting, sel_address, sel_PCconst, sel_write, sel_A, sel_B, sel_sr, EN_pc, EN_ir, EN_rf, start_read_mem, start_write_mem} = 14'b0;
    
    case(state)
      START: start_read_mem = 1'b1;
      PC_UP: begin sel_B = 2'd2; EN_ir = 1'b1; EN_pc = 1'b1; end
      LOADSR: begin  sr_parallel_load = 1'b1; end
      SHIFT: begin 
        sel_sr = 1'b1; 
        if (shamt != 4'h0) start_shifting = 1'b1; 
      end
      WRTRF: begin 
        EN_rf = 1'b1;
        sel_A = 1'b1;
        sel_B = selected_B; 
        if (OPcode[3:1] == 3'b100 && func == 2'b11) sel_write = 1'b1; 
      end
      PCRDY: begin sel_PCconst = 1'b1; EN_pc = 1'b1; end
      LRWRT: begin sel_A = 1'b1; sel_B = selected_B; EN_rf = 1'b1; sel_PCconst = 1'b1; EN_pc = 1'b1; end
      WRTMM: begin sel_A = 1'b1; sel_B = selected_B; start_write_mem = 1'b1; sel_address = 1'b1; end 
      READM: begin sel_A = 1'b1; sel_B = selected_B; start_read_mem = 1'b1; sel_address = 1'b1;  end
      WMTRF: begin sel_write = 1'b1; EN_rf = 1'b1; end
      default: {sr_parallel_load, start_shifting, sel_address, sel_PCconst, sel_write, sel_A, sel_B, sel_sr, EN_pc, EN_ir, EN_rf, start_read_mem, start_write_mem} = 14'b0;
    endcase
  end
endmodule
