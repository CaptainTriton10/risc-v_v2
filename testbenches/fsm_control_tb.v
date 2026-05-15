module fsm_control_tb;

reg [6:0] opcode;
reg clk, rst;

fsm_control dut(
    .clk(clk),
    .rst(rst),
    .opcode(opcode)
);

always #1 clk = ~clk;

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, dut);

    #0 begin
        clk = 0;
        rst = 1;
    end
    #5 rst = 0;

    #10 opcode = 7'b0110011;
    #10 opcode = 7'b0000011;
    #10 opcode = 7'b0100011;
    #10 opcode = 7'b1100011;
    #10 opcode = 7'b1101111;
    #10 opcode = 7'b0110111;

    #100 $finish;
end

endmodule