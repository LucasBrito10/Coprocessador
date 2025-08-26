module controler
(parameter img_height = 4,
parameter img_width = 4
)

(
output reg pixel_valid,
output reg out,
output reg x[3:0],
output reg y[3:0],
input wire clk,
input wire reset,
input wire start_button
input wire transit


);



//ESTADOS DA MAQUINA DE LEITURA DOS DADOS DA IMAGEM


parameter stopped = 2'b00,
          reading	 = 2'b01,
			 next_pixel = 2'b10,
          finished  = 2'b11;

//PROXIMO ESTADO E ESTADO ATUAL
reg [1:0] state, next_state;



//FLIP FLOP PARA VARIAR OS ESTADOS
always@(clk posedge)begin

	state <= next_state;

end





//MAQUINA LEITURA DA IMAGEM
always@(clk posedge) begin

	if(reset)begin
		state <= stopped;
		x <= 0;
		y <= 0;
	end
	
	
	else begin
	
		case(state) begin
		
			stopped: begin
			
				if(transit)begin
					next_state <= reading
					x <= 0;
					y <= 0;
					pixel_valid <= 1'b0;
					
				end
			
			end
			
			reading: begin
			
				if(transit)begin
               pixel_valid <= 1'b1;   // pixel_out da ROM está pronto para o proximo modulo
					next_state <= next_pixel;
				
				end
				
			end
				
			next_pixel: begin
					pixel_valid = 1'b0;
					if(transit)
					
			
			end
		
		
		
		endcase
	
	end
	

end


end









endmodule