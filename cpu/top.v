module top(
    input wire clk,
    input wire [1:0] button,
    input wire usb_rx,
    output wire [3:0] gpdi_dp
);

cpu cpu_inst(
    .clk(clk), .rst(~button[0]),
    .uart_rx(usb_rx), .gpdi_dp(gpdi_dp)
);

endmodule