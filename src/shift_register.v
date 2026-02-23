`default_nettype none

module shift_register(
  output reg [15:0] sr,
  input wire serial_in,
  input wire [15:0] parallel_in,
  input wire shift_direction,
  input wire en_serial_in,
  input wire en_parallel_load,
  input wire en_shift,
  input wire clk,
  input wire reset_n
);

  always @(posedge clk, negedge reset_n) begin
    if(!reset_n)
      sr <= 16'd0;
    else begin
      if(en_parallel_load)
        sr <= parallel_in;
      else if(en_shift) begin
        if (shift_direction)   // Left Shift (LSB로 데이터 유입)
                sr <= (en_serial_in) ? {sr[14:0], serial_in} : {sr[14:0], 1'b0};
            else                   // Right Shift (MSB는 0으로 채워짐)
                sr <= {1'b0, sr[15:1]};
      end
    end
  end

endmodule
