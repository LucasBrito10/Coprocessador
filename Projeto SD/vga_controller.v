module vga_controller (
    input wire clk,                 // Clock principal de 50MHz
    input wire reset,               // Reset assíncrono
    input wire [7:0] pixel_in,      // Pixel de 8-bits vindo do processador de imagem

    output wire [9:0] vga_x,        // Coordenada horizontal atual (0-799)
    output wire [9:0] vga_y,        // Coordenada vertical atual (0-524)
    output wire vga_display_area, // '1' quando estiver na área visível

    output reg VGA_HS,              // Sinal de Sincronismo Horizontal
    output reg VGA_VS,              // Sinal de Sincronismo Vertical
    output wire [7:0] vga_r,        // Canal de cor Vermelho (8-bit)
    output wire [7:0] vga_g,        // Canal de cor Verde (8-bit)
    output wire [7:0] vga_b         // Canal de cor Azul (8-bit)
);


    //Parâmetros Horizontais (em pixels)
    localparam H_DISPLAY      = 640;  // Largura visível
    localparam H_FRONT_PORCH  = 16;   // Borda frontal
    localparam H_SYNC_PULSE   = 96;   // Pulso de sincronismo
    localparam H_BACK_PORCH   = 48;   // Borda traseira
    localparam H_TOTAL        = H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; // 800 total

    //Parâmetros Verticais (em linhas)
    localparam V_DISPLAY      = 480;  // Altura visível
    localparam V_FRONT_PORCH  = 10;   // Borda frontal
    localparam V_SYNC_PULSE   = 2;    // Pulso de sincronismo
    localparam V_BACK_PORCH   = 33;   // Borda traseira
    localparam V_TOTAL        = V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; // 525 total

    reg [9:0] h_count = 0; // Contador horizontal (precisa de 10 bits para 800)
    reg [9:0] v_count = 0; // Contador vertical (precisa de 10 bits para 525)
    
    reg pixel_clk_enable = 1'b0;
    always @(posedge clk) begin
        pixel_clk_enable <= ~pixel_clk_enable;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else if (pixel_clk_enable) begin // Avança apenas no clock de 25MHz
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end
        end
    end


    
    // Sinais de Sincronismo (Ativos em nível baixo)
    always @(*) begin
        // O pulso HSYNC começa após a área visível e a borda frontal
        if ((h_count >= H_DISPLAY + H_FRONT_PORCH) && (h_count < H_DISPLAY + H_FRONT_PORCH + H_SYNC_PULSE))
            VGA_HS = 1'b0;
        else
            VGA_HS = 1'b1;

        // O pulso VSYNC começa após a área visível e a borda frontal
        if ((v_count >= V_DISPLAY + V_FRONT_PORCH) && (v_count < V_DISPLAY + V_FRONT_PORCH + V_SYNC_PULSE))
            VGA_VS = 1'b0;
        else
            VGA_VS = 1'b1;
    end

    // A área de display é onde ambos os contadores estão na faixa visível
    assign vga_display_area = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    
    // As saídas de coordenadas são simplesmente os contadores
    assign vga_x = h_count;
    assign vga_y = v_count;
    
    // Para escala de cinza, todos os canais (R, G, B) recebem o mesmo valor.
    // Fora da área de display, a saída é preta (0).
    assign vga_r = vga_display_area ? pixel_in : 8'h00;
    assign vga_g = vga_display_area ? pixel_in : 8'h00;
    assign vga_b = vga_display_area ? pixel_in : 8'h00;

endmodule