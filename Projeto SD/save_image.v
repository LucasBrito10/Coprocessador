module save_image#(

parameter img_height = 4, 
parameter img_width = 4

)(

input wire clk,
input wire reset,
input wire [3 : 0]x,
input wire [3 : 0]y,
output reg pixel_out_valid,
output reg [7:0]pixel_out

);


// vetor usado para salvar imagem na ROM. Cada elemeto do vetor tem, no máximo, 8 bits. O vetor é linear e possui 16 elementos possíveis.
//ISSO AQUI É A MINHA ROM(MAIS OU MENOS ISSO, ABSTRAÇÃO)

reg [7:0] image_data [0:15];

initial begin
    image_data[0]  = 8'd0;    image_data[1]  = 8'd64;
    image_data[2]  = 8'd128;  image_data[3]  = 8'd192;
    image_data[4]  = 8'd32;   image_data[5]  = 8'd96;
    image_data[6]  = 8'd160;  image_data[7]  = 8'd224;
    image_data[8]  = 8'd16;   image_data[9]  = 8'd80;
    image_data[10] = 8'd144;  image_data[11] = 8'd208;
    image_data[12] = 8'd48;   image_data[13] = 8'd112;
    image_data[14] = 8'd176;  image_data[15] = 8'd255;
end



always@(x or y)begin

pixel_out <= image_data[y*img_width + x];
pixel_out_valid <= 1;

end





endmodule