`default_nettype none

module IO(
  // 시스템 신호
  input wire clk,
  input wire reset_n,

  // CPU/Decoder 인터페이스
  input wire [15:0] write_data, // CPU가 쓰려는 데이터 (B 버스)
  output wire [15:0] read_data,  // CPU가 읽어갈 데이터
  input wire din_en,            // Digital In 활성화 (from Decoder)
  input wire dout_en,           // Digital Out 활성화 (from Decoder)
  input wire start_write,       // 쓰기 실행 신호

  // 물리적 핀 연결 (Tiny Tapeout 규격)
  input  wire [7:0] phys_in,    // ui_in[7:0]
  output reg  [7:0] phys_out    // uo_out[7:0]
);

  // 1. Digital Out (쓰기): 8비트 레지스터
  // CPU가 SW 명령으로 0x0008~0x000F 주소에 접근할 때 값을 갱신합니다.
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      phys_out <= 8'h00;
    end
    else if (dout_en && start_write) begin
      // CPU 데이터 버스의 하위 8비트를 출력 핀에 저장합니다.
      phys_out <= write_data[7:0];
    end
  end

  // 2. Digital In (읽기): 조합 회로
  // CPU가 LW 명령으로 0x0000~0x0007 주소에 접근할 때 핀 상태를 버스에 실어줍니다.
  // 선택되지 않았을 때는 0을 출력하여 버스 충돌을 방지합니다.
  assign read_data = (din_en) ? {8'h00, phys_in} : 16'h0000;

endmodule
