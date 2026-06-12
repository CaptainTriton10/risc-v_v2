`include "uart/params.vh"

module uart_rx #(
    parameter CLK = 50000000,
    parameter BAUD = 115200
) (
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [7:0] rx_data,
    output reg rx_valid
);

localparam CLKS_PER_BIT = CLK / BAUD;
localparam HALF = CLKS_PER_BIT / 2;
localparam CTR_WIDTH = $clog2(CLKS_PER_BIT + 1);

// Synchronise input
reg rx_async, rx_sync;
always @(posedge clk) begin
    rx_async <= rx;
    rx_sync <= rx_async;
end

reg [1:0] state;
reg [CTR_WIDTH-1:0] ctr;
reg [2:0] bit_index;
reg [7:0] sreg;

always @(posedge clk) begin
    if (rst) begin
        state <= `IDLE;
        ctr <= 0;
        bit_index <= 0;
        rx_valid <= 0;
    end else begin
        rx_valid <= 1'b0;

        case (state)
            `IDLE: begin
                if (!rx_sync) begin
                    state <= `START;
                    ctr <= 0;
                end
            end
            `START: begin
                    if (ctr == (HALF - 1)) begin
                    if (!rx_sync) begin
                        state <= `DATA;
                        ctr <= 0;
                        bit_index <= 0;
                    end else
                        state <= `IDLE;
                end else ctr <= ctr + 1;
            end
            `DATA: begin
                if (ctr == (CLKS_PER_BIT - 1)) begin
                    sreg <= {rx_sync, sreg[7:1]};
                    ctr <= 0;
                    if (bit_index == 3'd7)
                        state <= `STOP;
                    else
                        bit_index <= bit_index + 1;
                end else ctr <= ctr + 1;
            end
            `STOP: begin
                if (ctr == (CLKS_PER_BIT - 1)) begin
                    if (rx_sync) begin
                        rx_data <= sreg;
                        rx_valid <= 1'b1;
                    end
                    state <= `IDLE;
                    ctr <= 0;
                end else ctr <= ctr + 1;
            end
        endcase
    end
end

endmodule