`include "params.vh"

// `define TESTBENCH

`define RAM_SIZE 32768  // RAM size in bytes

module cpu(
    input wire clk,
    input wire rst,
    output wire [31:0] rs1,
    output wire [3:0] gpdi_dp
);

assign rs1 = rs1_data;

wire mem_read, mem_write;
wire reg_write, ir_write;

// wire [31:0] ir = ram_rd_data;
reg [31:0] ir;

wire [31:0] instr = ir;
wire [6:0] opcode = instr[6:0];
wire [2:0] funct3 = instr[14:12];
wire [6:0] funct7 = instr[31:25];

wire [4:0] rs1_index = instr[19:15];
wire [4:0] rs2_index = instr[24:20];
wire [4:0] rd_index  = instr[11:7];

wire [31:0] imm32;

wire branch_taken;

wire alu_a_src;
wire [1:0] alu_b_src;

wire [1:0] wb_sel;

wire [31:0] pc;
wire [31:0] pc_next1;
wire [31:0] pc_4 = pc + 32'h4;
wire pc_write;
wire [1:0] pc_src;
reg [31:0] pc_exec;

wire mem_addr_src;
wire [3:0] alu_op;

wire [31:0] rs1_data;
wire [31:0] rs2_data;

reg [31:0] alu_op_a;
reg [31:0] alu_op_b;

wire [31:0] alu_result;
reg [31:0] alu_out;

wire [31:0] mem_addr = alu_out;
reg [31:0] mem_addr_mux;

wire [31:0] ram_rd_data;
reg [31:0] mem_data_reg;
reg [3:0] byte_mask;

reg [31:0] reg_wr_data;

reg [31:0] pc_prev;

always @(posedge clk) begin
    pc_prev <= pc;

    if (ir_write) begin
        ir <= ram_rd_data;
        pc_exec <= pc_prev;
    end

    alu_out <= alu_result;
    mem_data_reg <= ram_rd_data;
end

wire vsync, hsync, de;
wire [7:0] vga_r, vga_g, vga_b;

wire [11:0] fb_addr;
wire [7:0] fb_data;

// DISPLAY OUTPUT //

`ifndef TESTBENCH
    // Generate pixel and tmds clock (25MHz and 250MHz)
    wire clkp, clkt;
    dvi_pll pll(.clk_in(clk), .clkp(clkp), .clkt(clkt), .locked());

    dvi_out dvi(
        .clkp(clkp),
        .fb_addr(fb_addr),
        .fb_data (fb_data),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vsync(vsync),
        .hsync(hsync),
        .de(de)
    );

    // Convert the signal to DVI and send over HDMI
    vga2tmds tmds_generator(
    	.clkp(clkp), .clkt(clkt),
    	.vsync(vsync), .hsync(hsync), .de(de),
    	.r(vga_r), .g(vga_g), .b(vga_b), .tmds(gpdi_dp)
    );
`endif

// CPU MODULES //

imm_decoder imm_decoder_inst(
    .instr(instr),
    .opcode(opcode),
    .imm32(imm32)
);

always @(*) begin
    reg_wr_data = 32'h0;
    case (wb_sel)
        `WB_ALU: reg_wr_data = alu_out;
        `WB_PC4: reg_wr_data = pc_4; // ALU calculates PC + 4
        `WB_MEM: reg_wr_data = mem_data_reg;
    endcase
end

registers registers_inst(
    .clk(clk), .we(reg_write),
    .wr_index(rd_index), .wr_data(reg_wr_data),
    .index_r1(rs1_index), .index_r2(rs2_index),
    .rd_data_r1(rs1_data), .rd_data_r2(rs2_data)
);

reg [31:0] wr_data_mux;

always @(*) begin
    case (mem_addr_src)
        `MEM_PC:   mem_addr_mux = pc;
        `MEM_ADDR: mem_addr_mux = mem_addr;
    endcase

    byte_mask = 4'b1111;
    wr_data_mux = rs2_data;

    case (funct3)
        3'b000: begin
            case (mem_addr_mux[1:0])
                2'b00: begin
                    byte_mask = 4'b1000;
                    wr_data_mux = {rs2_data[7:0], 24'b0};
                end
                2'b01: begin
                    byte_mask = 4'b0100;
                    wr_data_mux = {8'b0, rs2_data[7:0], 16'b0};
                end
                2'b10: begin
                    byte_mask = 4'b0010;
                    wr_data_mux = {16'b0, rs2_data[7:0], 8'b0};
                end
                2'b11: begin
                    byte_mask = 4'b0001;
                    wr_data_mux = {24'b0, rs2_data[7:0]};
                end
            endcase
        end
        3'b001:
            case (mem_addr_mux[1])
                1'b0: begin
                    byte_mask = 4'b1100;
                    wr_data_mux = {rs2_data[15:0], 16'b0};
                end
                1'b1: begin
                    byte_mask = 4'b0011;
                    wr_data_mux = {16'b0, rs2_data[15:0]};
                end
            endcase
        3'b010: begin
            byte_mask = 4'b1111;
            wr_data_mux = rs2_data;
        end
    endcase
end

ram ram_inst (
    .clk(clk),
    .data_addr(mem_addr_mux),
    .fb_addr(fb_addr),
    .we(mem_write), .re(mem_read),
    .byte_mask(byte_mask),
    .wr_data(wr_data_mux),
    .rd_data(ram_rd_data),
    .fb_data(fb_data)
);

defparam ram_inst.SIZE = `RAM_SIZE;

always @(*) begin
    case (alu_a_src)
        `ALU_A_RS1: alu_op_a = rs1_data;
        `ALU_A_PC:  alu_op_a = pc_exec;
        default:    alu_op_a = rs1_data;
    endcase

    case (alu_b_src)
        `ALU_B_RS2: alu_op_b = rs2_data;
        `ALU_B_IMM: alu_op_b = imm32;
        `ALU_B_4:   alu_op_b = 32'h00000004;
        default:    alu_op_b = rs2_data;
    endcase
end

alu alu_inst(
    .a(alu_op_a), .b(alu_op_b),
    .alu_op(alu_op), .result(alu_result)
);

pc_next pc_next_inst(
    .pc_src(pc_src),
    .alu_out(alu_out),
    .pc_inc(pc_4),
    .pc_next(pc_next1)
);

program_counter program_counter_inst(
    .clk(clk), .rst(rst),
    .pc_write(pc_write),
    .pc_next(pc_next1), .pc(pc)
);

comparator comparator_inst(
    .funct3(funct3),
    .rs1(rs1_data), .rs2(rs2_data),
    .taken(branch_taken)
);

control_unit control_unit_inst(
    .clk(clk), .rst(rst),
    .opcode(opcode), .funct3(funct3), .funct7(funct7),
    .branch_taken(branch_taken),
    .mem_read(mem_read), .mem_write(mem_write),
    .reg_write(reg_write), .ir_write(ir_write),
    .alu_a_src(alu_a_src), .alu_b_src(alu_b_src),
    .wb_sel(wb_sel),
    .pc_write(pc_write), .pc_src(pc_src),
    .mem_addr_src(mem_addr_src),
    .alu_op(alu_op)
);

endmodule