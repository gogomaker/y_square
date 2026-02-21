`default_nettype none

module ALU(
    output wire zero,
    output wire done_shift,
    output reg [15:0] answer,
    input wire [15:0] A,
    input wire [15:0] B,
    input wire [2:0] mode,
    input wire start_shift,
    input wire clk,
    input wire reset_n
);
    // 1. 가산기 통합 (Add/Sub/SLT를 하나로)
    wire [15:0] sub_B = (mode == 3'd1 || mode == 3'd5) ? ~B : B;
    wire cin = (mode == 3'd1 || mode == 3'd5) ? 1'b1 : 1'b0;
    wire [15:0] sum_result = A + sub_B + cin;

    // 2. 시프터 연결
    wire [15:0] shift_answer;
    shifter s(
        .answer(shift_answer),
        .done(done_shift),
        .data(A),
        .shamt(B[3:0]),
        .start(start_shift),
        .shifting_direction(mode[0]), // 6(110)->0, 7(111)->1
        .clk(clk),
        .reset_n(reset_n)
    );

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
