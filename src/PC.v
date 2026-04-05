`default_nettype none

module PC(
  output reg [15:0] address,
  input wire [15:0] load_constant,
  input wire clk,
  input wire reset_n, 
  input wire EN,
  input wire LOAD
);

  always @(posedge clk or negedge reset_n) begin
    if(!reset_n)
      address <= 16'd32;
    else if (EN) begin
      if (LOAD)
        address <= load_constant;
      else
        address <= address + 16'd1;
    end
  end
endmodule
