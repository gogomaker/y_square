`default_nettype none

module cpu_controller controller(
  input wire zero_flag,
  input wire [3:0] OPcode,
  output wire sel_address,
  output wire sel_PCconst,
  output wire EN_pc,
  output wire EN_ir,
  output wire EN_rf,
  output wire sel_A,
  output wire [1:0] sel_B,
  input wire clk,
  input wire reset_n
);
