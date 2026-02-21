`default_nettype none

module PC(
  output reg [15:0] address
  input wire [15:0] load_constant,
  input wire clk,
  input wire reset_n, 
  input wire EN,
);

  always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
      address <= 16'd32;
    else begin
      if(EN)
        address <= address + 16'd1;
      else 
        address <= load_constant;
    end
  end
endmodule
