module high_level (
    input wire CLOCK_50,
    input wire [9:0] SW,
    input wire [3:0] KEY,
    
    output wire VGA_HS,
    output wire VGA_VS,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,
    output wire VGA_BLANK_N,
    output wire VGA_CLK
);

    wire clk_vga;  // Clock de 25MHz para o VGA
    wire clk_core; // Clock de 100MHz para o processamento
    wire pll_locked;
    wire active_high_reset = ~KEY[0] | ~pll_locked;

    wire [9:0] x_vga, y_vga;
    wire       flow_enabled; // Indica área ativa da tela

    wire [$clog2(160)-1:0] x_img_from_zoom_in, mem_x_addr_from_zoom_out;
    wire [$clog2(120)-1:0] y_img_from_zoom_in, mem_y_addr_from_zoom_out;
    wire                   valid_from_zoom_in;
    wire [7:0]             pixel_from_zoom_out;
    wire                   pixel_valid_from_zoom_out;
    --
    wire [$clog2(160)-1:0] x_img_to_mem;
    wire [$clog2(120)-1:0] y_img_to_mem;
    wire [7:0]             pixel_from_mem;

    localparam VGA_WIDTH  = 640;
    localparam VGA_HEIGHT = 480;
    localparam IMG_WIDTH  = 160;
    localparam IMG_HEIGHT = 120;
    
    wire       zoom_in_out      = SW[9]; // 0 = Zoom Out, 1 = Zoom In
    wire       algorithm_select = SW[8]; // 0 = vizinho, 1 = replicação/média
    
    reg [1:0]  k_level;
    always @(*) begin
        if (SW[5])      k_level = 3; // 8x
        else if (SW[6]) k_level = 2; // 4x
        else if (SW[7]) k_level = 1; // 2x
        else            k_level = 0; // 1x
    end

    wire is_8x_zoom_in = zoom_in_out && (k_level == 3);
    reg [9:0] display_width;
    reg [9:0] display_height;
    always @(*) begin
        if (is_8x_zoom_in) begin
            display_width  = VGA_WIDTH;
            display_height = VGA_HEIGHT;
        end else if (k_level == 0) begin
            display_width  = IMG_WIDTH;
            display_height = IMG_HEIGHT;
        end else if (zoom_in_out) begin
            display_width  = IMG_WIDTH << k_level;
            display_height = IMG_HEIGHT << k_level;
        end else begin
            display_width  = IMG_WIDTH >> k_level;
            display_height = IMG_HEIGHT >> k_level;
        end
    end
    wire [9:0] h_offset = (VGA_WIDTH - display_width) / 2;
    wire [9:0] v_offset = (VGA_HEIGHT - display_height) / 2;
    wire image_on_screen = (x_vga >= h_offset) && (x_vga < h_offset + display_width) &&
                           (y_vga >= v_offset) && (y_vga < v_offset + display_height);
    wire [9:0] x_vga_adjusted = x_vga - h_offset;
    wire [9:0] y_vga_adjusted = y_vga - v_offset;
    localparam RECORTE_H_OFFSET_8X = ((IMG_WIDTH << 3) - VGA_WIDTH) / 2;
    localparam RECORTE_V_OFFSET_8X = ((IMG_HEIGHT << 3) - VGA_HEIGHT) / 2;
    wire [9:0] x_vga_for_zoom_in = is_8x_zoom_in ? (x_vga + RECORTE_H_OFFSET_8X) : x_vga_adjusted;
    wire [9:0] y_vga_for_zoom_in = is_8x_zoom_in ? (y_vga + RECORTE_V_OFFSET_8X) : y_vga_adjusted;


    clk_pll pll_inst (
        .refclk(CLOCK_50),
        .rst(~KEY[0]),
        .outclk_0(clk_vga),     // Saída de 25MHz
        .outclk_1(clk_core),   // Saída de 100MHz
        .locked(pll_locked)
    );

    vga_controller vga_inst (
        .clk(clk_vga),
        .reset(active_high_reset),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .x_vga(x_vga),
        .y_vga(y_vga),
        .flow_enabled(flow_enabled)
    );

    zoom_in zin_inst (
        .clk(clk_core), 
        .reset(active_high_reset), 
        .flow_enabled(zoom_in_out && flow_enabled && image_on_screen), 
        .algorithm_select(algorithm_select),
        .k(k_level),
        .x_vga(x_vga_for_zoom_in),
        .y_vga(y_vga_for_zoom_in),
        .x_img(x_img_from_zoom_in),
        .y_img(y_img_from_zoom_in),
        .valid(valid_from_zoom_in)
    );

    zoom_out zout_inst (
        .clk(clk_core),
        .reset(active_high_reset), 
        .flow_enabled(~zoom_in_out && flow_enabled && image_on_screen),
        .algorithm_select(algorithm_select),
        .k(k_level),
        .x_vga(x_vga_adjusted),
        .y_vga(y_vga_adjusted),
        .mem_x_addr(mem_x_addr_from_zoom_out),
        .mem_y_addr(mem_y_addr_from_zoom_out),
        .mem_pixel_in(pixel_from_mem),
        .pixel_out(pixel_from_zoom_out),
        .pixel_valid(pixel_valid_from_zoom_out)
    );

    memory #( .IMG_WIDTH(IMG_WIDTH), .IMG_HEIGHT(IMG_HEIGHT) ) mem_inst (
        .clk(clk_core),
        .reset(active_high_reset), 
        .flow_enabled(flow_enabled && image_on_screen),
        .x_img(x_img_to_mem),
        .y_img(y_img_to_mem),
        .pixel_out(pixel_from_mem),
        .pixel_out_valid()
    );


    assign x_img_to_mem = zoom_in_out ? x_img_from_zoom_in : mem_x_addr_from_zoom_out;
    assign y_img_to_mem = zoom_in_out ? y_img_from_zoom_in : mem_y_addr_from_zoom_out;
    
    wire [7:0] pixel_out_core_domain   = zoom_in_out ? pixel_from_mem : pixel_from_zoom_out;
    wire       pixel_valid_core_domain = zoom_in_out ? valid_from_zoom_in : pixel_valid_from_zoom_out;

    reg [7:0] pixel_out_vga_domain;
    always @(posedge clk_vga or posedge active_high_reset) begin
        if (active_high_reset) begin
            pixel_out_vga_domain <= 8'h00;
        end 

        else if (pixel_valid_core_domain) begin
            pixel_out_vga_domain <= pixel_out_core_domain;
        end
    end

    assign VGA_R = (flow_enabled && image_on_screen) ? pixel_out_vga_domain : 8'h00;
    assign VGA_G = VGA_R;
    assign VGA_B = VGA_R;

    assign VGA_CLK     = clk_vga; // O clock do VGA é o de 25MHz
    assign VGA_BLANK_N = flow_enabled;

endmodule