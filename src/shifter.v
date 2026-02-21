`default_nettype none

module shifter(
    output reg [15:0] answer,
    output reg done,
    input wire [15:0] data,
    input wire [3:0] shamt,
    input wire start,
    input wire shifting_direction,
    input wire clk,
    input wire reset_n
);
    localparam WAIT  = 2'b00;
    localparam LOAD  = 2'b01;
    localparam SHIFT = 2'b10;
    localparam DONE  = 2'b11;

    reg [1:0] current_state, next_state;
    reg [3:0] counter;
    reg EN, shift;

    // State Register
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) current_state <= WAIT;
        else         current_state <= next_state;
    end

    // Next State & Output Logic
    always @(*) begin
        next_state = current_state;
        {EN, shift, done} = 3'b000;

        case(current_state)
            WAIT: begin
                if(start) next_state = LOAD;
            end
            LOAD: begin
                // shamt가 0이면 바로 DONE으로, 아니면 SHIFT로
                next_state = (shamt == 4'h0) ? DONE : SHIFT;
                EN = 1'b1;
            end
            SHIFT: begin
                // 현재 시프트가 반영될 것이므로, (shamt-1)과 비교하거나 
                // counter를 미리 증가시켜 체크하는 것이 정확합니다.
                if (counter == shamt - 4'h1) next_state = DONE;
                else                         next_state = SHIFT;
                shift = 1'b1;
            end
            DONE: begin
                next_state = WAIT;
                done = 1'b1;
            end
        endcase
    end

    // Datapath
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n)
            answer <= 16'h0;
        else if(EN)
            answer <= data;
        else if(shift)
            answer <= shifting_direction ? (answer << 1) : (answer >> 1);
    end

    // Counter Control
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n || current_state == LOAD) // LOAD 시점에 초기화
            counter <= 4'h0;
        else if(shift)
            counter <= counter + 4'h1;
    end

endmodule
