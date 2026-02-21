`default_nettype none

module imm_gen(
  output wire [15:0] imm_address_extended,
  output wire [15:0] imm_extended,
  input wire [11:0] imm_address,
  input wire [5:0] imm,
  input wire [3:0] OPcode,
  input wire [2:0] PC
);
  assign imm_address_extended = {PC, imm_address, 0};  //byte address를 상정하고 만든 것임.
  assign imm_extended = (OPcode == 4'b1010) ? {10'b0, imm} : {10{imm[5]}, imm};
endmodule
