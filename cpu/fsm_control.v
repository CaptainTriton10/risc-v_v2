`include "params.vh"

module fsm_control (
    input wire clk, rst,
    input wire [6:0] opcode,
    input wire branch_taken,
    output reg mem_read, mem_write,
    output reg reg_write, ir_write,
    output reg alu_a_src,
    output reg [1:0] alu_b_src,
    output reg [1:0] wb_sel,
    output reg pc_write,
    output reg [1:0] pc_src,
    output reg mem_addr_src
);

reg [2:0] state, next_state;

always @(posedge clk or posedge rst) begin
    if (rst) state <= `S_FETCH;
    else state <= next_state;
end

always @(*) begin
    case (state)
        `S_FETCH: next_state = `S_DECODE;
        `S_DECODE: next_state = `S_EXECUTE;
        `S_EXECUTE: begin
            case (opcode)
                `OP_REG, `OP_IMM, `OP_LUI, `OP_AUIPC: next_state = `S_WRITEBACK;
                `OP_LOAD, `OP_STORE: next_state = `S_MEMORY;
                `OP_BRANCH: next_state = `S_FETCH;
                `OP_JAL, `OP_JALR: next_state = `S_WRITEBACK;
                default: next_state = `S_FETCH;
            endcase
        end
        `S_MEMORY: begin
            case (opcode)
                `OP_LOAD: next_state = `S_WRITEBACK;
                `OP_STORE: next_state = `S_FETCH;
                default: next_state = `S_FETCH;
            endcase
        end
        `S_WRITEBACK: next_state = `S_FETCH;
        default: next_state = `S_FETCH;
    endcase
end

always @(*) begin
    mem_read = 1'b0;
    mem_write = 1'b0;
    reg_write = 1'b0;
    ir_write = 1'b0;
    alu_a_src = 1'b0;
    alu_b_src = 2'b00;
    wb_sel = 2'b00;
    pc_write = 1'b0;
    pc_src = 2'b00;
    mem_addr_src = 1'b0;

    case (state)
        `S_FETCH: begin
            ir_write = 1'b1;
            mem_read = 1'b1;
            mem_addr_src = `MEM_PC;
            pc_write = 1'b1;
            pc_src = `PC_4;
            alu_a_src = `ALU_A_PC;
            alu_b_src = `ALU_B_4;
        end
        `S_DECODE: begin
            // Proactively calculate the branch target
            alu_a_src = `ALU_A_PC;
            alu_b_src = `ALU_B_IMM;
        end
        `S_EXECUTE: begin
            case (opcode)
                `OP_REG: begin
                    alu_a_src = `ALU_A_RS1;
                    alu_b_src = `ALU_B_RS2;
                end
                `OP_IMM: begin
                    alu_a_src = `ALU_A_RS1;
                    alu_b_src = `ALU_B_IMM;
                end
                `OP_JALR: begin
                    alu_a_src = `ALU_A_RS1;
                    alu_b_src = `ALU_B_IMM;
                    pc_write = 1'b1;
                    pc_src = `PC_IMM_RS1;
                end
                `OP_JAL: begin
                    alu_a_src = `ALU_A_PC;
                    alu_b_src = `ALU_B_IMM;
                    pc_write = 1'b1;
                    pc_src = `PC_IMM;
                end
                `OP_LOAD, `OP_STORE: begin
                    alu_a_src = `ALU_A_RS1;
                    alu_b_src = `ALU_B_IMM;
                end
                `OP_BRANCH: begin
                    pc_write = branch_taken;
                    pc_src = `PC_IMM;
                end
                `OP_LUI: begin
                    alu_b_src = `ALU_B_IMM;
                end
                `OP_AUIPC: begin
                    alu_a_src = `ALU_A_PC;
                    alu_b_src = `ALU_B_IMM;
                end
            endcase
        end
        `S_MEMORY: begin
            mem_addr_src = `MEM_ADDR;
            case (opcode)
                `OP_LOAD: mem_read = 1'b1;
                `OP_STORE: mem_write = 1'b1;
                default: ;
            endcase
        end
        `S_WRITEBACK: begin
            reg_write = 1'b1;
            case (opcode)
                `OP_REG, `OP_IMM, `OP_LUI: wb_sel = `WB_ALU;
                `OP_LOAD: wb_sel = `WB_MEM;
                `OP_JAL, `OP_JALR: wb_sel = `WB_PC4;
                default: ;
            endcase
        end
    endcase
end

endmodule
