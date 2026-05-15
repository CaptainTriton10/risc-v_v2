`include "params.vh"

module alu_control(
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire [6:0] opcode,
    output reg [3:0] alu_op
);

wire arith = funct7[5];

always @(*) begin
    case(opcode)
        7'b0110011: begin // R-type operations
            case (funct3)
                3'b000: alu_op = arith ? `ALU_SUB : `ALU_ADD;
                3'b001: alu_op = `ALU_SLL;
                3'b010: alu_op = `ALU_SLT;
                3'b011: alu_op = `ALU_SLTU;
                3'b100: alu_op = `ALU_XOR;
                3'b101: alu_op = arith ? `ALU_SRA : `ALU_SRL;
                3'b110: alu_op = `ALU_OR;
                3'b111: alu_op = `ALU_AND;
                default: alu_op = `ALU_ADD;
            endcase
        end
        7'b0010011: begin // I-type operations
            case (funct3)
                3'b000: alu_op = `ALU_ADD;
                3'b010: alu_op = `ALU_SLT;
                3'b011: alu_op = `ALU_SLTU;
                3'b100: alu_op = `ALU_XOR;
                3'b110: alu_op = `ALU_OR;
                3'b111: alu_op = `ALU_AND;
                3'b001: alu_op = `ALU_SLL;
                3'b101: alu_op = arith ? `ALU_SRA : `ALU_SRL;
                default: alu_op = `ALU_ADD;
            endcase
        end
        7'b0110111: alu_op = `ALU_PASS_B; // LUI requires value B to pass through the alu
        7'b0010111: alu_op = `ALU_ADD;    // AUIPC adds the immediate to the PC
        7'b1100111: alu_op = `ALU_ADD;    // JALR calculates the jump target with rs1 + imm
        7'b1101111: alu_op = `ALU_ADD;    // JAL calculates the jump target with PC + imm
        7'b0000011: alu_op = `ALU_ADD;    // LOAD calculates the address target with RS1 + imm
        7'b0100011: alu_op = `ALU_ADD;    // STORE calculates the address target with RS1 + imm
        default: alu_op = `ALU_ADD;
    endcase
end

endmodule