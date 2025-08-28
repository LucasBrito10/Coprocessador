module fsm_case (
    input  wire clk,
    input  wire reset,
    input  wire start,
    input  wire done,
    output reg  out
);
    // Declaração dos estados
    parameter IDLE=2'b00, RUN=2'b01, FINISH=2'b10;
    reg [1:0] state, next_state;

    // 1. Registro do estado
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 2. Transição de estados
    always @* begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = RUN;
                else
                    next_state = IDLE;
            end

            RUN: begin
                if (done)
                    next_state = FINISH;
                else
                    next_state = RUN;
            end

            FINISH: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // 3. Saídas baseadas no estado
    always @* begin
        case (state)
            IDLE:   out = 0;
            RUN:    out = 1;
            FINISH: out = 0;
            default: out = 0;
        endcase
    end

endmodule