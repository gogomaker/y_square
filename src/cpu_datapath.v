`default_nettype none

module cpu_datapath(
  output wire [15:0] address,         // to memory
  output wire [15:0] parallel_memory, // to memory
  output wire [15:0] parallel_out_shifter, // to shifter
  output wire [3:0] shamt,                 // to shifter
  output wire direction,                   // to shifter
  output reg zero_flag,          // to controller
  output wire [3:0] OPcode_ctr,  // to controller
  output wire [2:0] func_out,

  input wire [15:0] parallel_in_shifter, // from shifter
  input wire sel_address,  // from controller
  input wire sel_PCconst,  // from controller
  input wire sel_write,
  input wire sel_A,        // from controller
  input wire [1:0] sel_B,  // from controller
  input wire EN_pc,        // from controller
  input wire EN_ir,        // from controller
  input wire EN_rf,        // from controller
  input wire [2:0] mode,
  input wire clk,
  input wire reset_n
);
  wire zero;
  wire [2:0] Rd, Rs1, Rs2, func, OPcode;
  wire [15:0] data_IR, A, B, ALUout, address_PC, immAddress, immData;
  
  assign address = (sel_address) ? ALUout : address_PC;
  assign parallel_memory = B;
  assign parallel_out_shifter = A;
  assign OPcode_ctr = data_IR[15:12];
  assign func_out = func;
  always @(posedge clk)
    zero_flag <= zero;
  
  PC pc(
    .address(address_PC),
    .load_constant((sel_PCconst) ? immAddress : ALUout),
    .clk(clk),
    .reset_n(reset_n), 
    .EN(EN_pc)
  );
  
  IR ir(
    .OPcode(OPcode),
    .Rd(Rd),
    .Rs1(Rs1),
    .Rs2(Rs2),
    .func(func),
    .output_IR(data_IR),
    .input_IR(parallel_in_shifter),
    .clk(clk),
    .reset_n(reset_n),
    .en(EN_ir)
  );

  register_file rf(
    .regA(A),
    .regB(B),
    .Rd((OPcode == 3'b101) ? 3'b111 : Rd),
    .Rs1(Rs1),
    .Rs2(((OPcode == 3'b111) || (OPcode == 3'b001)) ? Rd : Rs2),
    .write_data(sel_write ? parallel_in_shifter : ALUout),
    .EN(EN_rf),
    .clk(clk),
    .reset_n(reset_n)
  );

  imm_gen im(
    .imm_address_extended(immAddress),
    .imm_extended(immData),
    .ir(data_IR),
    .PC(address_PC[15:13])
  );
  wire [15:0] selected_B;
  assign selected_B = (sel_B == 2'd0) ? B :
                      (sel_B == 2'd1) ? immData :
                      (sel_B == 2'd2) ? 16'd1 :
                                        16'd0;
  ALU alu(
    .zero(zero),           //for controller
    .shamt(shamt),         //for shifter
    .direction(direction), //for shifter
    .answer(ALUout),       //for ALU
    .A((sel_A) ? A : address_PC),   //for ALU
    .B(selected_B),           		//for ALU
    .mode(mode)
  );

endmodule
