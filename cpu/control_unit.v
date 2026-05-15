module control_unit(
    input wire clk, rst,
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire branch_taken,
    output wire mem_read, mem_write,
    output wire reg_write, ir_write,
    output wire alu_a_src,
    output wire [1:0] alu_b_src,
    output wire [1:0] wb_sel,
    output wire pc_write,
    output wire [1:0] pc_src,
    output wire mem_addr_src,
    output wire [3:0] alu_op
);

alu_control alu_control_inst(
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .alu_op(alu_op)
);

fsm_control fsm_control_inst(
    .clk(clk),
    .rst(rst),
    .opcode(opcode),
    .branch_taken(branch_taken),
    .mem_read(mem_read), .mem_write(mem_write),
    .reg_write(reg_write), .ir_write(ir_write),
    .alu_a_src(alu_a_src), .alu_b_src(alu_b_src),
    .wb_sel(wb_sel),
    .pc_write(pc_write), .pc_src(pc_src),
    .mem_addr_src(mem_addr_src)
);

endmodule