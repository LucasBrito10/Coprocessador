module resizing_core (
    
    input wire [7:0] p_in_00,   // canto superior esquerdo do bloco
    input wire [7:0] p_in_01,   // Canto superior direito do bloco
    input wire [7:0] p_in_10,   // Canto inferior esquerdo do bloco
    input wire [7:0] p_in_11,   // Canto inferior direito do bloco

    // Seletor para o algoritmo de redimensionamento a ser aplicado
    input wire [1:0] algorithm_select,

    output reg [7:0] pixel_out   // Pixel de 8 bits processado
);

    // Define códigos para os algoritmos
    localparam PASS_THROUGH  = 2'b00;  // 00: Pass-through (usado para Vizinho Mais Próximo, Replicação e Decimação)
    localparam BLOCK_AVERAGE = 2'b01;	// 01: Média de Bloco 2x2

    // A saída é calculada com base nas entradas atuais.
    always @(*) begin
        case (algorithm_select)
		  
            // A lógica de seleção do pixel correto é feita no módulo controlador
            // através do cálculo de endereço. Este módulo apenas repassa o pixel.
				
            PASS_THROUGH: begin
                pixel_out = p_in_00;
            end

            BLOCK_AVERAGE: begin
                // Variável temporária para armazenar a soma dos 4 pixels.
                // Deve ter pelo menos 10 bits para evitar overflow (4 * 255 = 1020).
                reg [9:0] sum;
                
                // Soma os 4 pixels do bloco 2x2.
                sum = p_in_00 + p_in_01 + p_in_10 + p_in_11;
                
                // Divide a soma por 4. Em hardware, isso é um simples deslocamento
                // de 2 bits para a direita (>> 2).
                pixel_out = sum >> 2;
            end

            // Caso padrão: se o seletor for inválido, a saída é preta.
            // Isso previne a criação de latches e garante um comportamento definido.
            default: begin
                pixel_out = 8'h00;
            end
            
        endcase
    end

endmodule

