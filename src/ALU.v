`default_nettype none

module ALU(
  output wire zero,          //for controller
  output wire [3:0] shamt,   //for shifter
  output wire direction      //for shifter
  output reg [15:0] answer,  //for ALU
  input wire [15:0] A,       //for ALU
  input wire [15:0] B,       //for ALU
  input wire [2:0] mode      //for ALU
  input wire [15:0] shift_answer //for shifter
);

    // 1. 가산기 통합 (Add/Sub/SLT를 하나로)
  wire [15:0] sub_B = (mode == 3'd1 || mode == 3'd5) ? ~B : B;
  wire cin = (mode == 3'd1 || mode == 3'd5) ? 1'b1 : 1'b0;
  wire [15:0] sum_result = A + sub_B + cin;

  // 2. 시프터 연결
  assign shamt = B[3:0];
  assign direction = mode[0];

  // 3. 결과 선택 (Mux 구조)
  always @(*) begin
    case(mode)
      3'd0,                                  // Add
      3'd1: answer = sum_result;             // Sub
      3'd2: answer = A & B;                  // AND
      3'd3: answer = A | B;                  // OR
      3'd4: answer = A ^ B;                  // XOR
      3'd5: answer = {15'b0, sum_result[15]}; // SLT (부호비트 활용)
      3'd6, 
      3'd7: answer = shift_answer;           // Shift
      default: answer = 16'h0;
    endcase
  end

  // 4. Zero Flag (NOR-reduction)
  assign zero = ~(|answer);

endmodule
