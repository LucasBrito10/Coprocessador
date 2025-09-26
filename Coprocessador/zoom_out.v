module zoom_out #(
    parameter IMG_WIDTH  = 160,
    parameter IMG_HEIGHT = 120,
    parameter DATA_WIDTH = 8
)(
    input wire clk, // Clock de 100 MHz
    input wire reset,
    input wire flow_enabled,

    // Seletor de algoritmo:
	 // 0 = Decimação
	 // 1 = Média de Blocos
    input  wire algorithm_select,
    input  wire [1:0] k,

    input  wire [9:0] x_vga,
    input  wire [9:0] y_vga,

    output reg [$clog2(IMG_WIDTH)-1:0]  mem_x_addr,
    output reg [$clog2(IMG_HEIGHT)-1:0] mem_y_addr,
    input  wire [DATA_WIDTH-1:0]       mem_pixel_in,

    output reg [DATA_WIDTH-1:0] pixel_out,
    output reg                  pixel_valid
);
    wire [$clog2(IMG_WIDTH)-1:0]  base_x = x_vga << k;
    wire [$clog2(IMG_HEIGHT)-1:0] base_y = y_vga << k;
    
    // Pipeline para o pixel da memória para compensar latência de 1 ciclo
    reg [DATA_WIDTH-1:0] mem_pixel_in_d1;

    // Lógica para Média de Blocos
    localparam STATE_IDLE       = 3'b000;
    localparam STATE_READ       = 3'b001;
    localparam STATE_ACCUMULATE = 3'b010;
    localparam STATE_CALC       = 3'b100;

    reg [2:0] state, next_state;
    reg [3:0] count_x, count_y;
    reg [DATA_WIDTH+7:0] sum;
    
    reg [$clog2(IMG_WIDTH)-1:0]  base_x_locked, prev_base_x;
    reg [$clog2(IMG_HEIGHT)-1:0] base_y_locked, prev_base_y;

    wire new_calc_needed = (state == STATE_IDLE) && ((base_x != prev_base_x) || (base_y != prev_base_y));
    wire [3:0] block_size = 1 << k;
    wire is_last_pixel = (count_x == block_size - 1) && (count_y == block_size - 1);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_pixel_in_d1 <= 0;
            prev_base_x     <= 0;
            prev_base_y     <= 0;
        end else begin
            mem_pixel_in_d1 <= mem_pixel_in;
            if (flow_enabled) begin
                prev_base_x <= base_x;
                prev_base_y <= base_y;
            end
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) state <= STATE_IDLE;
        else       state <= next_state;
    end

    always @(*) begin
        next_state = state;
        if (algorithm_select && k > 0) begin
            case(state)
                STATE_IDLE:       if (flow_enabled && new_calc_needed) next_state = STATE_READ;
                STATE_READ:       next_state = STATE_ACCUMULATE;
                STATE_ACCUMULATE: if (is_last_pixel) next_state = STATE_CALC;
                                  else next_state = STATE_READ;
                STATE_CALC:       next_state = STATE_IDLE;
            endcase
        end else begin
            next_state = STATE_IDLE;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sum <= 0;
            count_x <= 0;
            count_y <= 0;
            pixel_out <= 0;
            pixel_valid <= 1'b0;
            mem_x_addr <= 0;
            mem_y_addr <= 0;
            base_x_locked <= 0;
            base_y_locked <= 0;
        end else begin
            pixel_valid <= flow_enabled;
            
            if (~algorithm_select) begin
                mem_x_addr  <= base_x;
                mem_y_addr  <= base_y;
                pixel_out   <= mem_pixel_in_d1; 
                pixel_valid <= flow_enabled;
            end
            else begin
                if (k == 0) begin
                    mem_x_addr  <= base_x;
                    mem_y_addr  <= base_y;
                    pixel_out   <= mem_pixel_in_d1;
                    pixel_valid <= flow_enabled;
                end
                else begin
                    case(state)
                        STATE_IDLE: begin
                            if (flow_enabled && new_calc_needed) begin
                                count_x <= 0;
                                count_y <= 0;
                                sum <= 0; 
                                base_x_locked <= base_x;
                                base_y_locked <= base_y;
                            end
                        end
                        
                        STATE_READ: begin
                            mem_x_addr <= base_x_locked + count_x;
                            mem_y_addr <= base_y_locked + count_y;
                        end

                        STATE_ACCUMULATE: begin
                            // Para 2x (k=1), a média completa original é mantida.
                            if (k == 1) begin
                                sum <= sum + mem_pixel_in_d1;
                            end
                            // Para 4x (k=2), some apenas o bloco 2x2 central (índices 1 e 2).
                            else if (k == 2) begin
                                if ((count_x == 1 || count_x == 2) && (count_y == 1 || count_y == 2)) begin
                                    sum <= sum + mem_pixel_in_d1;
                                end
                            end
                            // Para 8x (k=3), some apenas o bloco 4x4 central (índices de 2 a 5).
                            else if (k == 3) begin
                                if ((count_x >= 2 && count_x <= 5) && (count_y >= 2 && count_y <= 5)) begin
                                    sum <= sum + mem_pixel_in_d1;
                                end
                            end
                            
                            // Avança os contadores para varrer o bloco inteiro
                            if (count_x < block_size - 1) begin
                                count_x <= count_x + 1;
                            end else begin
                                count_x <= 0;
                                count_y <= count_y + 1;
                            end
                        end

                        STATE_CALC: begin
                            if (k == 1) begin
                                pixel_out <= sum >> 2; // Divisor para 2x2 = 4
                            end else if (k == 2) begin
                                pixel_out <= sum >> 2; // Divisor para a sub-região 2x2 = 4
                            end else if (k == 3) begin
                                pixel_out <= sum >> 4; // Divisor para a sub-região 4x4 = 16
                            end
                        end
                    endcase
                end
            end
        end
    end
endmodule