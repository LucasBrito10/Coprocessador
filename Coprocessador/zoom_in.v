module zoom_in #(
    parameter WIDTH_IN  = 160,
    parameter HEIGHT_IN = 120
)(
    input  wire clk, // Clock de 100 MHz
    input  wire reset,
    input  wire flow_enabled,

    // Seletor de algoritmo:
    // 0 = Vizinho Mais Próximo
    // 1 = Replicação de Pixel
    input  wire algorithm_select,
    input  wire [1:0] k,

    input  wire [9:0] x_vga,
    input  wire [9:0] y_vga,

    output reg [$clog2(WIDTH_IN)-1:0]  x_img,
    output reg [$clog2(HEIGHT_IN)-1:0] y_img,
    output reg valid
);

    // Declara um registrador para armazenar o fator de zoom (2^k)
    reg [9:0] zoom_factor;

    always @(posedge clk) begin
        zoom_factor <= (1 << k);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_img <= 0;
            y_img <= 0;
            valid <= 1'b0;
        end
        else if (flow_enabled) begin
            valid <= 1'b1;

            case (algorithm_select)
           
                1'b0: begin
                    x_img <= x_vga >> k;
                    y_img <= y_vga >> k;
                end

                1'b1: begin
                    x_img <= x_vga / zoom_factor;
                    y_img <= y_vga / zoom_factor;
                end

            endcase
        end
        else begin
            valid <= 1'b0;
        end
    end

endmodule