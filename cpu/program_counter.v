module pc_next(
    input wire [1:0] pc_src,
    input wire [31:0] alu_out,
    input wire [31:0] pc_inc,
    output reg [31:0] pc_next
);

always @(*) begin
    case (pc_src)
        `PC_IMM, `PC_IMM_RS1:
            pc_next = alu_out;
        `PC_4:
            pc_next = pc_inc;
        default:
            pc_next = pc_inc;
    endcase
end

endmodule

module program_counter(
    input wire clk,
    input wire rst,
    input wire pc_write,
    input wire [31:0] pc_next,
    output reg [31:0] pc
);

always @(posedge clk) begin
    if (rst)
        pc <= 32'h0;
    else if (pc_write)
        pc <= pc_next;
end

endmodule