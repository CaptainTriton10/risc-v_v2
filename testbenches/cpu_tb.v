`include "params.vh"
`timescale 1ns/1ps

module cpu_tb;

// ──────────────────────────────────────────
// Clock & reset
// ──────────────────────────────────────────
reg clk = 0;
reg [1:0] button = 2'b01; // button[0] = rst

always #5 clk = ~clk;     // 100 MHz

// ──────────────────────────────────────────
// DUT
// ──────────────────────────────────────────
cpu dut (
    .clk(clk),
    .rst(button[0])
);

// ──────────────────────────────────────────
// Convenience aliases into DUT internals
// ──────────────────────────────────────────
`define PC        dut.pc
`define INSTR     dut.instr
`define STATE     dut.control_unit_inst.fsm_control_inst.state
`define REG(n)    dut.registers_inst.registers[n]
`define RAM(n)    dut.ram_inst.mem[n]
`define REG_WRITE dut.reg_write
`define WR_DATA   dut.reg_wr_data
`define WR_INDEX  dut.rd_index

// ──────────────────────────────────────────
// Waveform dump
// ──────────────────────────────────────────
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, cpu_tb);
end

// ──────────────────────────────────────────
// Test infrastructure
// ──────────────────────────────────────────
integer pass_count = 0;
integer fail_count = 0;

task check;
    input [63:0] got;
    input [63:0] expected;
    input [127:0] label;
    begin
        if (got === expected) begin
            $display("  PASS  %s  got=0x%08h", label, got);
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL  %s  got=0x%08h  expected=0x%08h", label, got, expected);
            fail_count = fail_count + 1;
        end
    end
endtask

// Wait for N complete instruction retirements.
// A retirement is a rising edge where reg_write fires OR
// where the FSM returns to S_FETCH after EXECUTE (branches/stores).
// Simpler: just wait enough cycles for N multicycle instructions.
// Each instruction takes at most 4 cycles (FETCH/DECODE/EXECUTE/WRITEBACK).
task wait_cycles;
    input integer n;
    integer i;
    begin
        for (i = 0; i < n; i = i + 1)
            @(posedge clk);
        #1; // settle combinational outputs
    end
endtask

// Load a small program into instruction RAM (word-addressed).
task load_program;
    input [31:0] i0, i1, i2, i3, i4, i5, i6, i7;
    integer i;
    begin
        for (i = 0; i < 32; i = i + 1)
            `REG(i) = 32'h0;

        `RAM(0) = i0; `RAM(1) = i1; `RAM(2) = i2; `RAM(3) = i3;
        `RAM(4) = i4; `RAM(5) = i5; `RAM(6) = i6; `RAM(7) = i7;
    end
endtask

// Assert reset for 2 cycles then release
task do_reset;
    begin
        button = 2'b01; // rst=1
        @(posedge clk); @(posedge clk);
        button = 2'b00; // rst=0
        @(posedge clk); // first fetch begins
    end
endtask

// ──────────────────────────────────────────
// NOP constant  (addi x0, x0, 0)
// ──────────────────────────────────────────
`define NOP 32'h00000013

// ──────────────────────────────────────────
// TESTS
// ──────────────────────────────────────────
initial begin
    $display("=== RV32I CPU Testbench ===");

    // ── TEST 1: ADDI ──────────────────────
    $display("\n[TEST 1] ADDI x1, x0, 42");
    // addi x1, x0, 42  →  x1 = 42
    load_program(
        32'h02a00093,  // addi x1, x0, 42
        `NOP, `NOP, `NOP, `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(4); // FETCH+DECODE+EXECUTE+WRITEBACK
    check(`REG(1), 32'd42, "x1 == 42");

    // ── TEST 2: Multiple ADDI / accumulation ──
    $display("\n[TEST 2] addi accumulation  x2 = 1+2+3 = 6");
    // addi x2, x0, 1
    // addi x2, x2, 2
    // addi x2, x2, 3
    load_program(
        32'h00100113,  // addi x2, x0, 1
        32'h00210113,  // addi x2, x2, 2
        32'h00310113,  // addi x2, x2, 3
        `NOP, `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(12);
    check(`REG(2), 32'd6, "x2 == 6");

    // ── TEST 3: ADD (R-type) ──────────────
    $display("\n[TEST 3] ADD x3, x1, x2  (42 + 6 = 48)");
    // Relies on x1=42 and x2=6 from previous tests surviving reset... they won't.
    // So set them up first.
    load_program(
        32'h02a00093,  // addi x1, x0, 42
        32'h00600113,  // addi x2, x0, 6
        32'h002081b3,  // add  x3, x1, x2
        `NOP, `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(12);
    check(`REG(3), 32'd48, "x3 == 48");

    // ── TEST 4: SUB ───────────────────────
    $display("\n[TEST 4] SUB x4, x1, x2  (42 - 6 = 36)");
    load_program(
        32'h02a00093,  // addi x1, x0, 42
        32'h00600113,  // addi x2, x0, 6
        32'h40208233,  // sub  x4, x1, x2
        `NOP, `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(12);
    check(`REG(4), 32'd36, "x4 == 36");

    // ── TEST 5: LUI ───────────────────────
    $display("\n[TEST 5] LUI x5, 0xABCDE  →  x5 = 0xABCDE000");
    load_program(
        32'hABCDE2B7,  // lui x5, 0xABCDE
        `NOP, `NOP, `NOP, `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(4);
    check(`REG(5), 32'hABCDE000, "x5 == 0xABCDE000");

    // ── TEST 6: AUIPC ─────────────────────
    $display("\n[TEST 6] AUIPC x6, 1  →  x6 = PC(0) + 0x1000 = 0x1000");
    load_program(
        32'h00001317,  // auipc x6, 1
        `NOP, `NOP, `NOP, `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(4);
    check(`REG(6), 32'h00001000, "x6 == 0x1000");

    // ── TEST 7: SW then LW ────────────────
    $display("\n[TEST 7] SW/LW round-trip  mem[64] = 0xDEADBEEF, LW x8 = 0xDEADBEEF");
    // addi x7, x0, 64     → base address
    // lui  x8, 0xDEADB    → x8 upper
    // addi x8, x8, 0xEEF  → careful: sign extends. Use ori instead or pick clean value.
    // For simplicity store the value 0x12345678 via two-instruction build:
    // lui  x8, 0x12345    → x8 = 0x12345000
    // addi x8, x8, 0x678  → x8 = 0x12345678
    // sw   x8, 0(x7)
    // lw   x9, 0(x7)
    load_program(
        32'h04000393,  // addi x7, x0, 64
        32'h12345437,  // lui  x8, 0x12345
        32'h67840413,  // addi x8, x8, 0x678
        32'h00839023,  // sw   x8, 0(x7)
        32'h0003a483,  // lw   x9, 0(x7)
        `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(24); // 5 instructions, loads/stores take extra cycle
    check(`REG(9), 32'h12345678, "x9 == 0x12345678");

    // ── TEST 8: BEQ taken ─────────────────
    $display("\n[TEST 8] BEQ taken — skips addi, x10 should stay 0");
    // addi x10, x0, 5
    // addi x11, x0, 5
    // beq  x10, x11, +8   (skip next instruction)
    // addi x10, x0, 99    ← should be skipped
    // addi x12, x0, 1     ← should execute, x12=1 confirms we landed here
    load_program(
        32'h00500513,  // addi x10, x0, 5
        32'h00500593,  // addi x11, x0, 5
        32'h00b50463,  // beq  x10, x11, +8
        32'h06300513,  // addi x10, x0, 99   ← skipped
        32'h00100613,  // addi x12, x0, 1
        `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(28);
    check(`REG(10), 32'd5,  "x10 == 5  (not overwritten)");
    check(`REG(12), 32'd1,  "x12 == 1  (landed after branch)");

    // ── TEST 9: BEQ not taken ─────────────
    $display("\n[TEST 9] BEQ not taken — executes addi");
    load_program(
        32'h00500513,  // addi x10, x0, 5
        32'h00600593,  // addi x11, x0, 6   (different from x10)
        32'h00b50463,  // beq  x10, x11, +8  ← not taken
        32'h06300513,  // addi x10, x0, 99   ← should execute
        `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(16);
    check(`REG(10), 32'd99, "x10 == 99 (branch not taken)");

    // ── TEST 10: AND / OR / XOR ───────────
    $display("\n[TEST 10] Bitwise ops");
    load_program(
        32'h0f000713,  // addi x14, x0, 0xF0
        32'h00f00793,  // addi x15, x0, 0x0F
        32'h00f77833,  // and  x16, x14, x15  → 0x00
        32'h00f768b3,  // or   x17, x14, x15  → 0xFF
        32'h00f74933,  // xor  x18, x14, x15  → 0xFF
        `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(20);
    check(`REG(16), 32'h00, "x16(AND) == 0x00");
    check(`REG(17), 32'hFF, "x17(OR)  == 0xFF");
    check(`REG(18), 32'hFF, "x18(XOR) == 0xFF");

    // ── TEST 11: SLT ──────────────────────
    $display("\n[TEST 11] SLT  x19 = (3 < 5) = 1");
    load_program(
        32'h00300993,  // addi x19, x0, 3
        32'h00500a13,  // addi x20, x0, 5
        32'h014929b3,  // slt  x19, x19, x20
        `NOP, `NOP, `NOP, `NOP, `NOP
    );
    do_reset;
    wait_cycles(12);
    check(`REG(19), 32'd1, "x19(SLT) == 1");

    // ── SUMMARY ───────────────────────────
    $display("\n=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
    if (fail_count == 0)
        $display("ALL TESTS PASSED");
    else
        $display("SOME TESTS FAILED");

    $finish;
end

// Timeout watchdog
initial begin
    #100000;
    $display("TIMEOUT — simulation hung");
    $finish;
end

endmodule