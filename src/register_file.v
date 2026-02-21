`default_nettype none

module register_file(
  output wire [15:0] regA,
  output wire [15:0] regB,
  input wire [2:0] Rd,
  input wire [2:0] Rs1,
  input wire [2:0] Rs2,
  input wire [15:0] write_data,
  input wire EN,
  input wire clk,
  input wire reset_n
);

  // 0번을 제외한 1~7번까지 7개의 레지스터만 선언
  reg [15:0] rf [1:7];

  // 1. Read Logic (Rs1, Rs2가 0일 경우 하드웨어적으로 0을 출력하도록 고정)
  // 0번 주소로 읽기 요청이 오면 레지스터를 참조하지 않고 상수 0을 반환하여 게이트 절약
  assign regA = (Rs1 == 3'b000) ? 16'h0 : rf[Rs1];
  assign regB = (Rs2 == 3'b000) ? 16'h0 : rf[Rs2];

  // 2. Write Logic
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      // 7개의 레지스터만 초기화
      rf[1] <= 16'h0;
      rf[2] <= 16'h0;
      rf[3] <= 16'h0;
      rf[4] <= 16'h0;
      rf[5] <= 16'h0;
      rf[6] <= 16'h0;
      rf[7] <= 16'h0;
    end
    else if (EN) begin
      if (Rd != 3'b000) // EN이 1이고, Rd가 0이 아닐 때만 쓰기 수행
        rf[Rd] <= write_data;
    end
  end
endmodule
