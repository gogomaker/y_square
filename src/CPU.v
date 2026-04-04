`default_nettype none

module CPU(
  output wire [15:0] address_memory,       // for SPI.v
  output wire [15:0] data_memory_out,      // for SPI.v
  output wire [15:0] parallel_out_shifter, // for shifter.v
  output wire start_shifting,              // for shifter.v
  output wire direction,                   // for shifter.v
  output wire sel_sr,                      // for shifter.v
  output wire sr_parallel_load,            // for shifter.v
  output wire start_read_mem,              // for SPI.v
  output wire start_write_mem,             // for SPI.v
  input wire [15:0] data_memory_in,        // from shifter.v
  input wire read_done,                    // from SPI.v
  input wire write_done,                   // from SPI.v
  input wire clk,
  input wire reset_n
);
  wire sel_address, sel_PCconst, EN_pc, EN_ir, EN_rf, sel_A, sel_B, zero_flag, sel_write;
  wire [2:0] OPcode;
  wire [1:0] func;
  wire [3:0] shamt;

  cpu_controller controller(
    .sel_address(sel_address),         // for datapath
    .sel_PCconst(sel_PCconst),         // for datapath
    .sel_write(sel_write),             // for datapath
    .sel_A(sel_A),                     // for datapath
    .sel_B(sel_B),                     // for datapath
    .sel_sr(sel_sr),                   // for datapath
    .EN_pc(EN_pc),                     // for datapath
    .EN_ir(EN_ir),                     // for datapath
    .EN_rf(EN_rf),                     // for datapath
    .start_read_mem(start_read_mem),   // for SPI.v
    .start_write_mem(start_write_mem), // for SPI.v
    .start_shifting(start_shifting),   // for shifter.v
    .sr_parallel_load(sr_parallel_load),// for shifter.v
    .OPcode(OPcode),                   // from dataapath
    .func(func),                       // from dataapath
    .zero_flag(zero_flag),             // from dataapath
    .shamt(shamt),                     // from dataapath
    .read_done(read_done),             // from SPI.v
    .write_done(write_done),           // from SPI.v
    .clk(clk),
    .reset_n(reset_n)
  );

  cpu_datapath datapath(
    .address(address_memory),                    // to SPI.v
    .parallel_memory(data_memory_out),           // to SPI.v
    .parallel_out_shifter(parallel_out_shifter), // to shifter.v
    .direction(direction),                       // to shifter.v
    .shamt(shamt),                               // to controller
    .zero_flag(zero_flag),                       // to controller
    .OPcode_ctr(OPcode),                         // to controller
    .func_out(func),                             // to controller
    .parallel_in_shifter(data_memory_in),        // from shifter
    .sel_address(sel_address),                   // from controller
    .sel_PCconst(sel_PCconst),                   // from controller
    .sel_write(sel_write),                       // from controller
    .sel_A(sel_A),                               // from controller
    .sel_B(sel_B),                               // from controller
    .EN_pc(EN_pc),                               // from controller
    .EN_ir(EN_ir),                               // from controller
    .EN_rf(EN_rf),                               // from controller
    .clk(clk),
    .reset_n(reset_n)
);
endmodule
