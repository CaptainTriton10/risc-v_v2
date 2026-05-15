module top(
    input wire clk,
    input wire [1:0] button,
    output wire [4:0] led,
    output wire [3:0] gpdi_dp
);

wire [31:0] rs1;

cpu cpu_inst(
    .clk(clk), .rst(~button[0]),
    .rs1(rs1), .gpdi_dp(gpdi_dp)
);

assign led = rs1[4:0];

endmodule