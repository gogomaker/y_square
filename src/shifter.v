`default_nettype none

module shifter(
  output reg [15:0] answer,
  input wire [15:0] parallel_in,
  input wire serial_in,
  input wire en_shift,    // 시프트 활성화 신호 (최우선순위)
  input wire en_load,     // 병렬 로딩 활성화 신호
  input wire direction,   // 1: Left, 0: Right
  input wire clk,
  input wire reset_n
);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      answer <= 16'd0;
    end
    // 1순위: 시프트 동작
    else if (en_shift) begin
      // direction == 1 (Left): LSB에 serial_in 삽입
      // direction == 0 (Right): MSB에 0 삽입
      answer <= (direction) ? {answer[14:0], serial_in} : {1'b0, answer[15:1]};
    end
    // 2순위: 병렬 로딩 동작
    else if (en_load) begin
      answer <= parallel_in;
    end
    // en_shift와 en_load가 모두 0이면 현재 값 유지 (자동 래치)
  end

endmodule
