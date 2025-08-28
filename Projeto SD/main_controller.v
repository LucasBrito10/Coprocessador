module main_controller #(
    parameter IMG_WIDTH = 160,
    parameter IMG_HEIGHT = 120
)(
    input wire clk,
    input wire reset,

    //Entradas do Controlador VGA
    input wire [9:0] vga_x,             // Coordenada X atual da tela (para 640x480)
    input wire [9:0] vga_y,             // Coordenada Y atual da tela
    input wire vga_display_area,      // '1' se estiver na área visível da tela

    //Entradas de Controle do Usuário
    input wire zoom_in_select,        // Chave para selecionar Zoom In
    input wire zoom_out_select,       // Chave para selecionar Zoom Out
    input wire use_block_avg_select,  // Chave para usar Média de Blocos no Zoom Out

    //Saída Final
    output reg [7:0] pixel_final_out    // Pixel processado para o controlador VGA
);

    //Parâmetros dos Algoritmos
    localparam PASS_THROUGH  = 2'b00;
    localparam BLOCK_AVERAGE = 2'b01;

    //Estados da Máquina de Estados (para Média de Blocos)
    localparam [1:0] IDLE        = 2'b00; // Estado ocioso e para algoritmos simples
    localparam [1:0] FETCH_P01   = 2'b01; // Busca pixel (0,1)
    localparam [1:0] FETCH_P10   = 2'b10; // Busca pixel (1,0)
    localparam [1:0] FETCH_P11   = 2'b11; // Busca pixel (1,1)

    reg [1:0] state, next_state;

    //Fios e Registradores para Comunicação Interna
    wire [7:0] rom_pixel_data;      // Dados lidos da ROM
    reg [$clog2(IMG_WIDTH*IMG_HEIGHT)-1:0] rom_addr; // Endereço para a ROM

    reg [7:0] p00_reg, p01_reg, p10_reg, p11_reg; // Registradores para armazenar o bloco 2x2
    reg [1:0] selected_algorithm;

    image_rom #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) u_image_rom (
        .clk(clk),
        .addr(rom_addr),
        .pixel_out(rom_pixel_data)
    );

    resizing_core u_resizing_core (
        .p_in_00(p00_reg),
        .p_in_01(p01_reg),
        .p_in_10(p10_reg),
        .p_in_11(p11_reg),
        .algorithm_select(selected_algorithm),
        .pixel_out(pixel_final_out)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            p00_reg <= 8'h00;
            p01_reg <= 8'h00;
            p10_reg <= 8'h00;
            p11_reg <= 8'h00;
        end else begin
            state <= next_state;

            // Armazena os pixels lidos da ROM conforme a FSM avança
            // A ROM tem 1 ciclo de latência: pedimos no estado A, o dado chega no estado B.
            case(state)
                IDLE:        p00_reg <= rom_pixel_data; // Armazena o pixel para pass-through ou o primeiro do bloco
                FETCH_P01:   p01_reg <= rom_pixel_data; // Armazena p(0,1)
                FETCH_P10:   p10_reg <= rom_pixel_data; // Armazena p(1,0)
                FETCH_P11:   p11_reg <= rom_pixel_data; // Armazena p(1,1)
            endcase
        end
    end

    always @(*) begin
        //temporárias
        reg [$clog2(IMG_WIDTH)-1:0]  src_x;
        reg [$clog2(IMG_HEIGHT)-1:0] src_y;
        reg is_in_bounds;
        
        next_state = IDLE;
        
        rom_addr = 0; // Endereço seguro
        selected_algorithm = PASS_THROUGH;

        if (vga_display_area) begin
            //Determina as coordenadas da imagem de origem e o algoritmo
            if (zoom_in_select) begin // MODO ZOOM IN 2X (Vizinho mais próximo)
                src_x = vga_x >> 1;
                src_y = vga_y >> 1;
                selected_algorithm = PASS_THROUGH;

            end else if (zoom_out_select) begin // MODO ZOOM OUT 2X
                src_x = vga_x << 1;
                src_y = vga_y << 1;
                if (use_block_avg_select) begin
                    selected_algorithm = BLOCK_AVERAGE; // Média de Blocos
                else
                    selected_algorithm = PASS_THROUGH; // Decimação
                end
            end else begin // MODO 1:1 (Normal)
                src_x = vga_x;
                src_y = vga_y;
                selected_algorithm = PASS_THROUGH;
            end

            //Verifica se a coordenada calculada está dentro da imagem
            is_in_bounds = (src_x < IMG_WIDTH) && (src_y < IMG_HEIGHT);
            
            if (is_in_bounds) begin
                 //Lógica da FSM para calcular endereços e transições
                case(state)
                    IDLE: begin
                        // Calcula o endereço do pixel (ou do canto superior esquerdo do bloco)
                        rom_addr = src_y * IMG_WIDTH + src_x;
                        if (selected_algorithm == BLOCK_AVERAGE) begin
                            // Se for média, inicia a sequência de busca
                            next_state = FETCH_P01;
                        end else begin
                            // Senão, continua em IDLE para o próximo pixel da tela
                            next_state = IDLE;
                        end
                    end
                    
                    FETCH_P01: begin
                        // Pede o pixel à direita
                        rom_addr = src_y * IMG_WIDTH + (src_x + 1);
                        next_state = FETCH_P10;
                    end

                    FETCH_P10: begin
                        // Pede o pixel abaixo
                        rom_addr = (src_y + 1) * IMG_WIDTH + src_x;
                        next_state = FETCH_P11;
                    end

                    FETCH_P11: begin
                        // Pede o pixel na diagonal
                        rom_addr = (src_y + 1) * IMG_WIDTH + (src_x + 1);
                        next_state = IDLE; // Fim da sequência, volta ao IDLE
                    end
                endcase
            end else begin
                // Fora dos limites da imagem, desenha preto. Mantém a FSM em IDLE.
                rom_addr = 0; 
                next_state = IDLE;
            end
        end else begin
            // Fora da área de display do VGA, reseta para IDLE.
            next_state = IDLE;
        end
    end

endmodule