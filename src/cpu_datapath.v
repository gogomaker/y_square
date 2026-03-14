`default_nettype none

module cpu_datapath(
  output wire [15:0] address,     // to memory
  output wire [15:0] parallel_memory, // to memory
  output wire [15:0] parallel_out_shifter, // to shifter
  output reg zero_flag,  // to controller
  output wire [2:0] OPcode,  // to controller

  input wire [15:0] parallel_in_shifter, // from shifter
  input wire clk,
  input wire reset_n
);
  wire [2:0] Rd, Rs1, Rs2, func;
  wire [15:0] data_IR, A, B, ALUout;
  
  pc PC(
    .address(),
    .load_constant(),
    .clk(clk),
    .reset_n(reset_n), 
    .EN(),
  );
  
  ir IR(
    .OPcode(OPcode),
    .Rd(Rd),
    .Rs1(Rs1),
    .Rs2(Rs2),
    .func(func),
    .output_IR(data_IR),
    .input_IR(parallel_in_shifter),
    .clk(clk),
    .reset_n(reset_n),
    .en()
  );

  rf register_file(
    regA(A),
    regB(B),
    Rd(Rd),
    Rs1(Rs1),
    Rs2(Rs2),
    write_data(() ? ALUout : parallel_in_shifter),
    EN(),
    clk(clk),
    reset_n(reset_n)
  );



  
endmodule
