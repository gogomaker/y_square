`timescale 1ns / 1ps
`default_nettype none

module IR(
  output wire [3:0] OPcode,
  output wire [2:0] Rd,
  output wire [2:0] Rs1,
  output wire [2:0] Rs2,
  output wire [2:0] func,
  output wire [5:0] imm,
  output wire [11:0] imm_address,
  input wire [3:0] mem,
  input wire clk,
  input wire reset_n, 
  input wire [3:0] EN
);

  reg [15:0] register;
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
  
  assign OPcode = register[15:12];
  assign Rd = register[11:9];
  assign Rs1 = register[8:6];
  assign Rs2 = register[5:3];
  assign func = register[2:0];
  assign imm = register[5:0];
  assign imm_address = register[11:0];

endmodule
