module resizing
#(
	parameter img_height = 4,
	parameter img_width = 4,
	parameter max_scale = 8

)

(
	input wire [7:0] pixel_in,
	input wire clk,
	input wire reset,
	input wire zoom_in,
	input wire zoom_out,
	input wire [1:0] scale,
	output reg [7:0] pixel_out

);


//ARRAY PARA CAPTURAR OS PIXELS

reg [7:0] new_image [0:(max_scale * img_height) - 1][0:(max_scale * img_width) - 1];





//ALGORITMO PARA REDIMENSIONAMENTO (ZOOM_IN)



