`timescale 1ns / 1ps
`default_nettype none

module MDR(
  output reg [15:0] register,
  input wire [3:0] mem,
  input wire clk,
  input wire reset_n, 
  input wire [3:0] EN
);

  always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
      register <= 16'h0;
    else begin
      case(EN)
        4'b1000: register[15:12] <= mem;
        4'b0100: register[11:8]  <= mem;
        4'b0010: register[7:4]   <= mem;
        4'b0001: register[3:0]   <= mem;
        default: register <= register;
      endcase
    end
  end
endmodule
