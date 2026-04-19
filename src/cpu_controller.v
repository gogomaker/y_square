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
  output reg sr_parallel_load,
  output reg [2:0] mode,
  input wire [3:0] shamt,
  input wire [3:0] OPcode,
  input wire [2:0] func,
  input wire zero_flag,
  input wire read_done,
  input wire write_done,
  input wire clk,
  input wire reset_n
);

  // define state
  reg [3:0] state, next_state;
  localparam START = 4'h0;  // reset state
  localparam WAITM = 4'h1;  // wait memory latency state 1
  localparam PC_UP = 4'h2;  // PC increase state
  localparam LDSHR = 4'h3;  // load data on the SR
  localparam SHIFT = 4'h4;  // for SLR, SLL state 
  localparam WRTRF = 4'h5;  // write register file state
  localparam UPCIM = 4'h6;  // for J
  localparam LRWRT = 4'h7;  // for JAL
  localparam JMPRT = 4'h8;  // for JR
  localparam READM = 4'h9;  // Read memory state
  localparam WRTMM = 4'hA;  // write memory state
  localparam WMTRF = 4'hB;
  localparam BEQAL = 4'hC;  // for BEQ
  localparam BRNCH = 4'hD;  // for BEQ
  localparam IRUDE = 4'hE;  // IR update
  
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
      START: next_state = WAITM;
      WAITM: next_state = (read_done) ? IRUDE : WAITM;
      IRUDE: next_state = PC_UP;
      PC_UP: begin
        if(OPcode[3:1] == 3'b100)
          next_state = (func[2:1] == 2'b11) ? LDSHR : WRTRF; 
        else if(OPcode[3:1] == 3'b000 || OPcode[3:1] == 3'b010)
          next_state = WRTRF;
        else if(OPcode[3:1] == 3'b011)
          next_state = UPCIM;
        else if(OPcode == 4'b1010)
          next_state = LRWRT;
        else if(OPcode == 4'b1011)
          next_state = JMPRT;
        else if(OPcode[3:1] == 3'b111)
          next_state = WRTMM;
        else if(OPcode[3:1] == 3'b110)
          next_state = READM;
        else if(OPcode[3:1] == 3'b001)
          next_state = BEQAL;
        else
          next_state = START;
      end
      LDSHR: next_state = SHIFT;
      SHIFT: next_state = (shamt == 4'h0 || shift_counter == shamt - 4'h1) ? WMTRF : SHIFT;
      WRTRF: next_state = START;
      UPCIM: next_state = START;
      LRWRT: next_state = START;
      JMPRT: next_state = START;
      WRTMM: next_state = (write_done) ? START : WRTMM;
      READM: next_state = (read_done)  ? WMTRF : READM;
      WMTRF: next_state = START;
      BEQAL: next_state = BRNCH;
      BRNCH: next_state = START;
      default: next_state = START;
    endcase
  end

  // for shift function
  reg [3:0] shift_counter;
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
      shift_counter <= 4'h0;
    else if(state == SHIFT)
      shift_counter <= shift_counter + 4'h1;
    else
      shift_counter <= 4'h0;
  end
  
  wire [2:0] pre_mode = (OPcode[3:1] == 3'b100) ? func : (OPcode[3] == 1'b0) ? OPcode[3:1] : 3'b000;         //for ALU
  wire [1:0] selected_B = (OPcode[3:1] == 3'b100) ? 2'd0 : (OPcode[3:1] == 3'b101) ? 2'd3 : 2'd1;
  // define current output
  always @(*) begin
    {sr_parallel_load, start_shifting, sel_address, sel_PCconst, sel_write, sel_A, sel_B, sel_sr, EN_pc, EN_ir, EN_rf, start_read_mem, start_write_mem} = 15'b0;
    mode = pre_mode;
    case(state)
      START: start_read_mem = 1'b1;
      IRUDE: EN_ir = 1'b1;
      PC_UP: begin sel_B = 2'd2;  EN_pc = 1'b1; mode = 2'b0; end
      LDSHR: begin sr_parallel_load = 1'b1; sel_sr = 1'b1; end
      SHIFT: begin 
        sel_sr = 1'b1; 
        if (shamt != 4'h0) start_shifting = 1'b1; 
      end
      WRTRF: begin 
        EN_rf = 1'b1;
        sel_A = 1'b1;
        sel_B = selected_B; 
        if (OPcode[3:1] == 3'b100 && func[2:1] == 2'b11) sel_write = 1'b1; 
      end
      UPCIM: begin sel_PCconst = 1'b1; EN_pc = 1'b1; end
      LRWRT: begin sel_B = selected_B; EN_rf = 1'b1; sel_PCconst = 1'b1; EN_pc = 1'b1; end
      JMPRT: begin sel_A = 1'b1; sel_B = selected_B; EN_pc = 1'b1; end
      READM: begin sel_A = 1'b1; sel_B = selected_B; start_read_mem = 1'b1; sel_address = 1'b1;  end
      WRTMM: begin sel_A = 1'b1; sel_B = selected_B; start_write_mem = 1'b1; sel_address = 1'b1; end 
      WMTRF: begin sel_write = 1'b1; EN_rf = 1'b1; end
      BEQAL: begin sel_A = 1'b1; sel_B = 2'b0; end
      BRNCH: begin sel_B = selected_B; EN_pc = zero_flag; mode = 3'b0; end
      default: begin {sr_parallel_load, start_shifting, sel_address, sel_PCconst, sel_write, sel_A, sel_B, sel_sr, EN_pc, EN_ir, EN_rf, start_read_mem, start_write_mem} = 15'b0; mode = pre_mode; end
    endcase
  end
endmodule
