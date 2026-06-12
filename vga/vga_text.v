module vga_text #(
    parameter COLS = 80,
    parameter ROWS = 30,
    parameter CHAR_WIDTH = 16,
    parameter BIT_DEPTH = 8
) (
    input wire clk,
    input wire [9:0] px,
    input wire [9:0] py,
    input wire [CHAR_WIDTH-1:0] fb_data,
    output wire [$clog2(COLS*ROWS)-1:0] fb_addr,
    output reg [BIT_DEPTH-1:0] r,
    output reg [BIT_DEPTH-1:0] g,
    output reg [BIT_DEPTH-1:0] b
);

reg [7:0] font [0:4095];

initial begin
    $readmemh("font3.hex", font);
end

wire [11:0] base_x = {{7{1'b0}}, px[9:3]};
wire [11:0] base_y = {{6{1'b0}}, py[9:4]};

wire [2:0] gpx = px[2:0];
wire [3:0] gpy = py[3:0];

reg [3:0] gpy_r1;
reg [2:0] gpx_r1;
reg active_r1;

always @(posedge clk) begin
    gpy_r1    <= gpy;
    gpx_r1    <= gpx;
    active_r1 <= active;
end

wire active = (px < (COLS << 3)) && (py < (ROWS << 4));
wire [11:0] font_addr = {fb_data[15:8], gpy_r1};

assign fb_addr = active ? ((base_y << 4) + (base_y << 6)) + base_x : 0;

reg [7:0] glyph_row;

reg [2:0] gpx_r2;
reg       active_r2;

always @(posedge clk) begin
    glyph_row <= font[font_addr];
    gpx_r2    <= gpx_r1;
    active_r2 <= active_r1;
end

wire pixel_active = glyph_row[7 - gpx_r2];

always @(posedge clk) begin
    if (active_r2 && pixel_active) begin
        // Shift by 6 to convert 2 bit to 8 bit
        r <= (fb_data[7:6] << 6);
        g <= (fb_data[5:4] << 6); 
        b <= (fb_data[3:2] << 6);
    end else begin
        r <= 8'h52;
        g <= 8'h52;
        b <= 8'hFF;
    end
end

endmodule