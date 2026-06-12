module uart_mmio(
    input wire clk,
    input wire rst,
    input wire rx,
    input wire chip_select,
    input wire [3:0] addr,
    input wire rd_en,
    output reg [31:0] rd_data,
    output wire irq
);

wire [7:0] rx_data;
wire rx_valid;

uart_rx uart_rx_inst(
    .clk(clk), .rst(rst), .rx(rx),
    .rx_data(rx_data), .rx_valid(rx_valid)
);

reg [7:0] rx_buf;
reg rx_ready, overflow;

wire cpu_rd_data;
assign cpu_rd_data = chip_select && rd_en && (addr[2] == 1'b0);

always @(posedge clk) begin
    if (rst) begin
        rx_buf <= 8'h00;
        rx_ready <= 1'b0;
        overflow <= 1'b0;
    end else begin
        if (rx_valid) begin
            rx_buf <= rx_data;
            overflow <= rx_ready && !cpu_rd_data;
            rx_ready <= 1'b1;
        end else if (cpu_rd_data) begin
            rx_ready <= 1'b0;
            overflow <= 1'b0;
        end
    end
end

assign irq = rx_ready;

always @(*) begin
    rd_data = 32'h0;

    if (chip_select && rd_en) begin
        case (addr[2])
            1'b0: rd_data = {24'h0, rx_buf};
            1'b1: rd_data = {30'h0, overflow, rx_ready};
        endcase
    end
end

endmodule