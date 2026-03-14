`timescale 1ns / 1ps
`default_nettype none

module IR(
  output wire [2:0] OPcode,
  output wire [2:0] Rd,
  output wire [2:0] Rs1,
  output wire [2:0] Rs2,
  output wire [2:0] func,
  output wire [15:0] output_IR,
  input wire [15:0] input_IR,
  input wire clk,
  input wire reset_n,
  input wire en
);

  reg [15:0] register;
  always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
      register <= 16'h0;
    else if(en)
      register <= input_IR;
  end
  
  assign OPcode = register[15:13];
  assign Rd = register[12:10];
  assign Rs1 = register[9:7];
  assign Rs2 = register[6:4];
  assign func = register[3:1];
  assign output_IR = register;

endmodule
