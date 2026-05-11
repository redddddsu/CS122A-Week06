// `include "src/sprite_buf_EX1.sv"
`include "src/sprite_buf_EX2.sv"

module top
(
    input  CLK, //FPGA's clocck

    input logic mosi,
    input logic sclk,
    input logic cs,
    output logic miso,

	output LCD_CLK,//LCD clock. 
	output LCD_DEN,
	output [4:0] LCD_R,
	output [5:0] LCD_G,
	output [4:0] LCD_B
);


lcd u_lcd (
    .mosi(mosi),
    .sclk(sclk),
    .cs(cs),
    .miso(miso),
    .rst(0),      
    .pclk(CLK),
    .LCD_DE(LCD_DEN),
    .LCD_R(LCD_R),
    .LCD_G(LCD_G),
    .LCD_B(LCD_B)
);
assign LCD_CLK = CLK;

endmodule

module lcd
(
    input logic mosi,
    input logic sclk,
    input logic cs,
    output logic miso,


    input  rst,
    input  pclk, 
    input [15:0] pixel,
    output [7:0] pixel_address,        

    output LCD_DE,      // Display Enable

    output [4:0] LCD_B, // 5-bit blue color data
    output [5:0] LCD_G, // 6-bit green color data
    output [4:0] LCD_R  // 5-bit red color data
);

parameter H_ACTIVE = 480;
parameter V_ACTIVE = 272;

parameter H_TOTAL = 525;
parameter V_TOTAL = 285;

logic[10:0] horizontal;
logic[10:0] vertical;

logic[7:0]  waddr;
logic[15:0] wdata;
logic we;

logic[15:0] shift_reg;
logic[5:0] bit_counter;
always_ff @(posedge sclk) begin
    we <= 0;
    if (!cs) begin
        shift_reg <= {shift_reg[14:0], mosi};
        if (bit_counter == 15) begin
            wdata <= {shift_reg[14:0], mosi};
            waddr <= waddr + 1;
            we <= 1;
            bit_counter <= 0;
        end
        else begin
            bit_counter <= bit_counter + 1;
        end
    end
    else begin
        bit_counter <= 0;
        shift_reg <= 0;
    end
end

assign pixel_address = {vertical[3:0], horizontal[3:0]};

dp_buffer u_dp_buffer(
    .clk(pclk),
    .raddr(pixel_address),
    .rdata(pixel),
    .waddr(waddr),
    .wdata(wdata),
    .we(we)
);



always_ff @(posedge pclk) begin
    if (rst) begin
        horizontal <= 0;
        vertical <= 0;
    end else begin 
        if (horizontal == H_TOTAL - 1) begin
            horizontal <= 0;
            if (vertical == V_TOTAL - 1)
                vertical <= 0;
            else
                vertical <= vertical + 1;
        end else begin
            horizontal <= horizontal + 1;
end
    
    end
end

always_ff @(posedge pclk) begin
    LCD_DE <= (horizontal < H_ACTIVE) && (vertical < V_ACTIVE);
end

always_ff @(posedge pclk) begin
    if (LCD_DE) begin
        LCD_R <= pixel[15:11];
        LCD_G <= pixel[10:5];
        LCD_B <= pixel[4:0];
    end else begin
        LCD_R <= 0;
        LCD_G <= 0;
        LCD_B <= 0;
    end
end



endmodule