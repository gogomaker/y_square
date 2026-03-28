`default_nettype none

module CPU(
  output wire [15:0] address_memory,
  output wire [15:0] data_memory_out,
  output wire [15:0] parallel_out_shifter,
  output wire [3:0] shamt,
  output wire direction,
  output wire sel_sr,
  input wire [15:0] data_memory_in,
  input wire clk,
  input wire reset_n
);

  wire sel_address, sel_PCconst, EN_pc, EN_ir, EN_rf, sel_A, sel_B, zero_flag;
  wire [2:0] OPcode;

  cpu_controller controller(
    .zero_flag(zero_flag),
    .OPcode(OPcode),
    .sel_address(sel_address),  // from controller
    .sel_PCconst(sel_PCconst),  // from controller
    .sel_write(sel_write),
    .sel_A(sel_A),  // from controller
    .sel_B(sel_B),  // from controller
    .sel_sr(sel_sr),
    .EN_pc(EN_pc),  // from controller
    .EN_ir(EN_ir),  // from controller
    .EN_rf(EN_rf),  // from controller
    .clk(clk),
    .reset_n(reset_n)
  );

  
  cpu_datapath datapath(
    .address(address_memory),     // to memory
    .parallel_memory(data_memory_out), // to memory
    .parallel_out_shifter(parallel_out_shifter), // to shifter
    .shamt(shamt), // to shifter
    .direction(direction),// to shifter
    .zero_flag(zero_flag),  // to controller
    .OPcode_ctr(OPcode),  // to controller

    .parallel_in_shifter(), // from shifter
    .sel_address(sel_address),  // from controller
    .sel_PCconst(sel_PCconst),  // from controller
    .sel_write(sel_write),
    .sel_A(sel_A),  // from controller
    .sel_B(sel_B),  // from controller
    .EN_pc(EN_pc),  // from controller
    .EN_ir(EN_ir),  // from controller
    .EN_rf(EN_rf),  // from controller
    .clk(clk),
    .reset_n(reset_n)
);
endmodule
