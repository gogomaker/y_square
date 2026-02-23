`default_nettype none

module shifter(
  output reg done,
  output reg en_parallel_load,
  output reg en_shift,
  input wire [3:0] shamt,
  input wire start,
  input wire clk,
  input wire reset_n
);
  localparam WAIT  = 2'b00;
  localparam LOAD  = 2'b01;
  localparam SHIFT = 2'b10;
  localparam DONE  = 2'b11;

  reg [1:0] current_state, next_state;
  reg [3:0] counter;
  reg en_parallel_load, en_shift;

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
endmodule
