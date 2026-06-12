module ram #(
    parameter SIZE = 32768,
    parameter FB_BLOCK = 16'h6000
) (
    input wire clk,
    input wire [31:0] data_addr,
    input wire [11:0] fb_addr,
    input wire we,
    input wire re,
    input wire [3:0] byte_mask,
    input wire [31:0] wr_data,
    output reg [15:0] fb_data,
    output reg [31:0] rd_data
);

localparam WORDS = SIZE / 4;
localparam FB_BLOCK_W = FB_BLOCK / 4;

wire [$clog2(WORDS)-1:0] word_data_addr  = data_addr[2 +: $clog2(WORDS)];

(* ram_style = "block" *) reg [31:0] mem [(WORDS)-1:0];

initial begin
    // $readmemh("vga/all_text.hex", mem, FB_BLOCK_W, WORDS);
    $readmemh("program.hex", mem, 0, FB_BLOCK_W);
end

reg [31:0] fb_word;
reg [1:0] fb_byte_off_r;

always @(posedge clk) begin
    if (we) begin
        if (byte_mask[3]) mem[word_data_addr][24 +: 8] <= wr_data[24 +: 8];
        if (byte_mask[2]) mem[word_data_addr][16 +: 8] <= wr_data[16 +: 8];
        if (byte_mask[1]) mem[word_data_addr][8  +: 8] <= wr_data[8  +: 8];
        if (byte_mask[0]) mem[word_data_addr][0  +: 8] <= wr_data[0  +: 8];
    end

    if (re) rd_data <= mem[word_data_addr];

    fb_word <= mem[fb_addr[11:1] + FB_BLOCK_W];
    fb_byte_off_r <= fb_addr[0];
end

always @(*) begin
    case (fb_byte_off_r)
        1'b0: fb_data = fb_word[31:16];
        1'b1: fb_data = fb_word[15:0];
    endcase
end

endmodule