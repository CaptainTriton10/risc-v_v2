module top(
    input wire clk,
    input wire [1:0] button,
    output wire [3:0] gpdi_dp
);

cpu cpu_inst(
    .clk(clk), .rst(~button[0]),
    .gpdi_dp(gpdi_dp)
);

endmodule