module top_level (
   
    input  wire       CLOCK_50,   // Clock principal de 50MHz
    input  wire [9:0] SW,         // 10 Chaves (Switches)
    input  wire [3:0] KEY,        // 4 Botões de pressão (ativos em nível baixo)

    // Conector VGA
    output wire [7:0] VGA_R,      // Canal Vermelho (8 bits)
    output wire [7:0] VGA_G,      // Canal Verde (8 bits)
    output wire [7:0] VGA_B,      // Canal Azul (8 bits)
    output wire       VGA_HS,     // Sincronismo Horizontal
    output wire       VGA_VS,     // Sincronismo Vertical
    
    output wire       VGA_CLK,
    output wire       VGA_BLANK_N,
    output wire       VGA_SYNC_N
);

    // Lógica de Reset: O botão KEY[0] é usado como reset.
    // Os botões da DE1-SoC são ativos em nível baixo, então invertemos o sinal.
    wire reset = ~KEY[0];

    // Fios para conectar os módulos internos.
    wire [9:0] vga_x_wire;
    wire [9:0] vga_y_wire;
    wire       vga_display_area_wire;
    wire [7:0] final_pixel_wire;

    // Mapeamento das chaves para os sinais de controle do sistema.
    // Esta é a interface do utilizador com o hardware.
    wire zoom_in_select       = SW[0]; // Chave 0: Liga/Desliga Zoom In
    wire zoom_out_select      = SW[1]; // Chave 1: Liga/Desliga Zoom Out
    wire use_block_avg_select = SW[2]; // Chave 2: Usa Média de Blocos (se Zoom Out estiver ativo)

    // 1. Instância do nosso controlador principal, o cérebro do projeto.
    //    Ele contém a ROM da imagem, o resizing_core e a máquina de estados.
    main_controller u_main (
        .clk(CLOCK_50),
        .reset(reset),

        // Conecta às saídas do controlador VGA
        .vga_x(vga_x_wire),
        .vga_y(vga_y_wire),
        .vga_display_area(vga_display_area_wire),

        // Conecta aos controlos físicos (chaves)
        .zoom_in_select(zoom_in_select),
        .zoom_out_select(zoom_out_select),
        .use_block_avg_select(use_block_avg_select),

        // A saída de pixel final que será enviada para o VGA
        .pixel_final_out(final_pixel_wire)
    );

    // 2. Instância do controlador de vídeo, que gera os sinais para o monitor.
    vga_controller u_vga (
        .clk(CLOCK_50),
        .reset(reset),

        // Recebe o pixel final do nosso controlador principal
        .pixel_in(final_pixel_wire),

        // Saídas que informam a posição atual na tela
        .vga_x(vga_x_wire),
        .vga_y(vga_y_wire),
        .vga_display_area(vga_display_area_wire),

        // Saídas conectadas diretamente aos pinos físicos do conector VGA
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .vga_r(VGA_R),
        .vga_g(VGA_G),
        .vga_b(VGA_B)
    );
    
    // prática atribuir-lhes valores definidos para evitar que fiquem a flutuar.
    assign VGA_CLK = CLOCK_50; // O clock para o DAC é geralmente o clock de pixel
    assign VGA_BLANK_N = 1'b1; // Não estamos a usar o blanking explícito
    assign VGA_SYNC_N = 1'b0;  // Sync-on-green, não utilizado

endmodule
