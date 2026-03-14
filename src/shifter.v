`default_nettype none

module shifter(
  output reg [15:0] answer,
  output reg done,
  input wire [3:0] shamt,
  input wire [15:0] parallel_in,
  input wire serial_in,
  input wire start,
  input wire clk,
  input wire reset_n,
  input wire direction  //0이 right, 1이 left
);
  localparam WAIT  = 2'b00;
  localparam LOAD  = 2'b01;
  localparam SHIFT = 2'b10;
  localparam DONE  = 2'b11;

  reg en_parallel_load, en_shift;
  reg [1:0] current_state, next_state;
  reg [3:0] counter;

  // State Register
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n) current_state <= WAIT;
    else         current_state <= next_state;
  end

  // Next State & Output Logic
  always @(*) begin
    next_state = current_state;
    {en_parallel_load, en_shift, done} = 3'b000;
    case(current_state)
      WAIT: begin
        if(start) next_state = LOAD;
      end
      LOAD: begin
        next_state = (shamt == 4'h0) ? DONE : SHIFT;
        en_parallel_load = 1'b1;
      end
      SHIFT: begin
        if (counter == shamt - 4'h1) next_state = DONE;
        else                         next_state = SHIFT;
        en_shift = 1'b1;
      end
      DONE: begin
        next_state = WAIT;
        done = 1'b1;
      end
    endcase
  end

  // Counter Control
  always @(posedge clk or negedge reset_n) begin
    if(!reset_n || current_state == LOAD) // LOAD 시점에 초기화
      counter <= 4'h0;
    else if(en_shift)
      counter <= counter + 4'h1;
  end

  // shift register
  always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
      answer <= 16'd0;
    else if(en_parallel_load)
      answer <= parallel_in;
    else if(en_shift)
      answer <= (direction) ? {answer[14:0], serial_in} : {1'b0, answer[15:1]};
  end
endmodule
