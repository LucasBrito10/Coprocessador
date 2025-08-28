module image_rom #(
    parameter IMG_WIDTH = 160,
    parameter IMG_HEIGHT = 120
) (
    input wire clk,
    // O endereço é um vetor único (y * LARGURA + x)
    input wire [$clog2(IMG_WIDTH * IMG_HEIGHT) - 1:0] addr,
    output reg [7:0] pixel_out
);

    // Declara a memória que será sintetizada como Block RAM (BRAM)
    reg [7:0] memory [0:(IMG_WIDTH * IMG_HEIGHT) - 1];

    // Inicializa a memória na hora da compilação com os dados do arquivo
    initial begin
        $readmemh("image_memory.hex", memory);
    end

    // A leitura da BRAM é síncrona (ocorre na borda de subida do clock)
    always @(posedge clk) begin
        pixel_out <= memory[addr];
    end

endmodule