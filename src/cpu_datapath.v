`default_nettype none

module cpu_datapath(
  output wire [15:0] address,     // to memory
  output wire [15:0] parallel_memory, // to memory
  output wire [15:0] parallel_out_shifter, // to shifter
  output wire [3:0] shamt, // to shifter
  output wire direction,// to shifter
  output reg zero_flag,  // to controller
  output wire [2:0] OPcode,  // to controller

  input wire [15:0] parallel_in_shifter, // from shifter
  input wire sel_address,  // from controller
  input wire sel_PCconst,  // from controller
  input wire EN_pc,  // from controller
  input wire EN_ir,  // from controller
  input wire EN_rf,  // from controller
  input wire sel_A,  // from controller
  input wire [1:0] sel_B,  // from controller
  input wire clk,
  input wire reset_n
);
  wire zero;
  wire [2:0] Rd, Rs1, Rs2, func;
  wire [15:0] data_IR, A, B, ALUout, address_PC, immAddress, immData;
  
  assign address = (sel_address) ? ALUout : address_PC;

  always @(posedge clk)
    zero_flag <= zero;
  
  pc PC(
    .address(address_PC),
    .load_constant((sel_PCconst) ? immAddress : ALUout),
    .clk(clk),
    .reset_n(reset_n), 
    .EN(EN_pc),
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
    .en(EN_ir)
  );

  rf register_file(
    regA(A),
    regB(B),
    Rd((OPcode == 3'b101) ? 3'b111 : Rd),
    Rs1(Rs1),
    Rs2(((OPcode == 3'b111) || (OPcode == 3'b001)) ? Rd : Rs2),
    write_data((OPcode == 3'b110) ? ALUout : parallel_in_shifter),
    EN(EN_rf),
    clk(clk),
    reset_n(reset_n)
  );

  imm_gen(
    imm_address_extended(immAddress),
    imm_extended(immData),
    ir(data_IR),
    PC(address_PC)
  );

  ALU(
    zero(zero),           //for controller
    shamt(shamt),         //for shifter
    direction(direction), //for shifter
    shift_answer(parallel_in_shifter) //for shifter
    answer(ALUout),       //for ALU
    A((sel_A) ? address_PC : A),        //for ALU
    B((sel_B[1]) ? 
      ((sel_B[0]) ? Rs2 : immData) : 
      ((sel_B[0]) ? 16'd2 : 16'd0)),           //for ALU
    mode((OPcode = 3'b101) ? func : 
         (OPcode[2] == 1'b0) ? OPcode : 
         3'b000)         //for ALU
);

endmodule
