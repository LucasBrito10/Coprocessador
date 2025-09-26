module controller
#(parameter img_height = 4,
  parameter img_width  = 4
)
(
    output reg pixel_valid,
    output reg out,
    output reg [3:0] x,
    output reg [3:0] y,
    input  wire clk,
    input  wire reset,
    input  wire start_button,
    input  wire data_pixel
);

// ESTADOS
parameter STOPPED    = 2'b00,
          READING    = 2'b01,
          NEXT_PIXEL = 2'b10,
          FINISHED   = 2'b11;

reg [1:0] state, next_state;


//SEPARAR LOGICA DE ESTADO ATUAL DO PROXIMO ESTADO

// REGISTRO DO ESTADO

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= STOPPED;
        x <= 0;
        y <= 0;
    end 
	 
	 else begin
        state <= next_state;

        // Atualiza coordenadas apenas nos estados certos
        if (state == STOPPED && start_button) begin
            x <= 0;
            y <= 0;
        end
        else if (state == NEXT_PIXEL) begin
            if (x < img_width - 1) begin
                x <= x + 1;
            end
            else if (x == img_width - 1 && y < img_height - 1) begin
                x <= 0;
                y <= y + 1;
            end
        end
    end
end


// LÓGICA DE PRÓXIMO ESTADO
always @(*) begin
    next_state  = state;      
    pixel_valid = 1'b0;   
	


	 if(!start_button)begin
		
		next_state = STOPPED;
	 end
	 
	 else begin
    
	 case (state)
		  
	 
        STOPPED: begin
            if (start_button)
                next_state = READING;
           
        end

        READING: begin
            if (data_pixel)
                next_state = NEXT_PIXEL;
            else
                next_state = STOPPED;
					 

        end

        NEXT_PIXEL: begin
            pixel_valid = 1'b1;
            if ((x == img_width - 1) && (y == img_height - 1))
                next_state = FINISHED;
            else
                next_state = READING;
        end

        FINISHED: begin
            next_state = STOPPED; 
        end

        default: next_state = STOPPED;
    endcase
	end
end

endmodule