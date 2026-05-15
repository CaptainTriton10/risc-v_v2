`include "params.vh"

module alu #(
    parameter REG_ADDR_WIDTH = 5
) (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_op,
    output reg [31:0] result
);

always @(*) begin
    case (alu_op)
        `ALU_ADD:    result = a + b;
        `ALU_SUB:    result = a - b;
        `ALU_AND:    result = a & b;
        `ALU_OR:     result = a | b;
        `ALU_XOR:    result = a ^ b;
        `ALU_SLL:    result = a << b[REG_ADDR_WIDTH-1:0];
        `ALU_SRL:    result = a >> b[REG_ADDR_WIDTH-1:0];
        `ALU_SRA:    result = a >>> b[REG_ADDR_WIDTH-1:0];
        `ALU_SLT:    result = $signed(a) < $signed(b) ? 32'h00000001 : 32'h0;
        `ALU_SLTU:   result = a < b ? 32'h00000001 : 32'h0;
        `ALU_PASS_B: result = b;
        default:     result = a + b;
    endcase
end

endmodule