`default_nettype none

module imm_gen(
  output wire [15:0] imm_address_extended,
  output wire [15:0] imm_extended,
  input wire [15:0] ir,
  input wire [2:0] PC
);
  assign imm_address_extended = {PC, ir[12:0]};  //word address를 상정하고 만든 것임.
  assign imm_extended = (ir[15:13] == 3'b010) ? {9'b0, ir[6:0]} : {9{ir[6]}, ir[6:0]};
endmodule
