module memory #(
    parameter IMG_WIDTH  = 160,
    parameter IMG_HEIGHT = 120,
    parameter ZOOM_FACTOR = 4  
)(
    input  wire       clk, // Clock de 100 MHz
    input  wire       reset,
    input  wire       flow_enabled,
	 
    input  wire [$clog2(IMG_WIDTH)-1:0]  x_img,
    input  wire [$clog2(IMG_HEIGHT)-1:0] y_img,
    
    output reg        pixel_out_valid,
    output reg [7:0]  pixel_out
);

	localparam ADDR_WIDTH = $clog2(IMG_WIDTH * IMG_HEIGHT);

    // ROM da imagem
    reg [7:0] image_data [0:IMG_WIDTH*IMG_HEIGHT-1];
    initial begin
        $readmemb("image.txt", image_data);
    end


    // Endereço na ROM
    wire [ADDR_WIDTH-1:0] addr;
    assign addr = y_img * IMG_WIDTH + x_img;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_out       <= 8'h00;
            pixel_out_valid <= 1'b0;
        end
        else if (flow_enabled) begin
            if (x_img < IMG_WIDTH && y_img < IMG_HEIGHT) begin
                pixel_out       <= image_data[addr];
                pixel_out_valid <= 1'b1;
            end else {pixel_out, pixel_out_valid} <= {8'h00, 1'b0};
        end
        else {pixel_out, pixel_out_valid} <= {8'h00, 1'b0};
    end

endmodule