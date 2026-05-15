module ram #(
    parameter SIZE_BITS = 32768,
    parameter FB_BLOCK = 9'h1A8
) (
    input wire clk,
    input wire [31:0] data_addr,
    input wire [11:0] fb_addr,
    input wire we,
    input wire re,
    input wire [3:0] byte_mask,
    input wire [31:0] wr_data,
    output reg [7:0] fb_data,
    output reg [31:0] rd_data
);

localparam WORDS = SIZE_BITS / 32;

wire [$clog2(WORDS)-1:0] word_data_addr  = data_addr[2 +: $clog2(WORDS)];

initial begin
    // $readmemh("fb.hex", mem, 424, 1024);
    $readmemh("program.hex", mem, 0, 423);
end

(* ram_style = "block" *) reg [31:0] mem [(WORDS)-1:0];

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

    fb_word <= mem[fb_addr[11:2] + FB_BLOCK];
    fb_byte_off_r <= fb_addr[1:0];
end

always @(*) begin
    case (fb_byte_off_r)
        2'b00: fb_data = fb_word[31:24];
        2'b01: fb_data = fb_word[23:16];
        2'b10: fb_data = fb_word[15: 8];
        2'b11: fb_data = fb_word[ 7: 0];
    endcase
end

endmodule