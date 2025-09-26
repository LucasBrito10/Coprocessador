module vga_controller (
    input wire clk,             // Clock de 25 MHz
    input wire reset,         
    
    output reg hsync,
    output reg vsync,
    output reg [9:0] x_vga,
    output reg [9:0] y_vga,
    
    output wire flow_enabled    // Sinal que indica a área visível
);

    localparam H_PIXELS = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = H_PIXELS + H_FRONT + H_SYNC + H_BACK; // 800

    localparam V_PIXELS = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = V_PIXELS + V_FRONT + V_SYNC + V_BACK; // 525

    // Toda a lógica foi unificada em um único bloco síncrono
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_vga <= 0;
            y_vga <= 0;
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            // Contador Horizontal avança a cada ciclo
            if (x_vga < H_TOTAL - 1) begin
                x_vga <= x_vga + 1;
            end else begin
                x_vga <= 0;
                // Contador Vertical só avança quando uma linha horizontal termina
                if (y_vga < V_TOTAL - 1) begin
                    y_vga <= y_vga + 1;
                end else begin
                    y_vga <= 0;
                end
            end
            
            // Gera o pulso de HSYNC (ativo baixo)
            if (x_vga >= H_PIXELS + H_FRONT && x_vga < H_PIXELS + H_FRONT + H_SYNC) begin
                hsync <= 1'b0;
            end else begin
                hsync <= 1'b1;
            end

            // Gera o pulso de VSYNC (ativo baixo)
            if (y_vga >= V_PIXELS + V_FRONT && y_vga < V_PIXELS + V_FRONT + V_SYNC) begin
                vsync <= 1'b0;
            end else begin
                vsync <= 1'b1;
            end
        end
    end

    // Ele se baseia nas saídas já registradas (x_vga, y_vga), então será estável.
    assign flow_enabled = (x_vga < H_PIXELS) && (y_vga < V_PIXELS);

endmodule