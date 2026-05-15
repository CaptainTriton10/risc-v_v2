`ifndef PARAMS_VH
`define PARAMS_VH

`define S_FETCH     3'd0
`define S_DECODE    3'd1
`define S_EXECUTE   3'd2
`define S_MEMORY    3'd3
`define S_WRITEBACK 3'd4

// What writes to the destination register
`define WB_ALU 2'b00
`define WB_PC4 2'b01
`define WB_MEM 2'b10

`define ALU_A_RS1 1'b0
`define ALU_A_PC  1'b1

`define ALU_B_RS2 2'b00
`define ALU_B_IMM 2'b01
`define ALU_B_4   2'b10

// What is written to the PC
`define PC_4       2'b00 // PC + 4 increment
`define PC_IMM     2'b01 // ALU output for branch or JAL, calculated with PC + IMM
`define PC_IMM_RS1 2'b10 // ALU output for JALR, calculated with RS1 + IMM

`define MEM_PC   1'b0 // For FETCH
`define MEM_ADDR 1'b1 // For LOAD/STORE

`define OP_REG    7'b0110011
`define OP_IMM    7'b0010011
`define OP_LOAD   7'b0000011
`define OP_STORE  7'b0100011
`define OP_BRANCH 7'b1100011
`define OP_JAL    7'b1101111
`define OP_JALR   7'b1100111
`define OP_LUI    7'b0110111
`define OP_AUIPC  7'b0010111

`define ALU_ADD    4'd0
`define ALU_SUB    4'd1
`define ALU_AND    4'd2
`define ALU_OR     4'd3
`define ALU_XOR    4'd4
`define ALU_SLL    4'd5
`define ALU_SRL    4'd6
`define ALU_SRA    4'd7
`define ALU_SLT    4'd8
`define ALU_SLTU   4'd9
`define ALU_PASS_B 4'hF // For LUI

`endif
