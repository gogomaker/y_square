`default_nettype none

module reg_16bit(
  output reg [15:0] register,
  input wire [15:0] input_data,
  input wire EN,
  input wire clk,
  input wire reset_n
);
  always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
      register <= 16'h0;
    else if(EN)
      register <= input_data;
  end
endmodule
