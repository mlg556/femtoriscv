`include "counter.v"
`include "clk_div.v"
`include "memory.v"

module memory_fpga (
    input clk,
    input resetn,
    output [5:0] led
);
    wire clk_slow;
    wire [31:0] mem_out;
    wire [31:0] count_val;
    // clkdiv
    clk_div #(
        .N(21)
    ) clk_div_i0 (
        .clk(clk),
        .clk_out(clk_slow)
    );
    // counter
    counter #(
        .INC(4)
    ) counter_i1 (
        .clk(clk_slow),
        .resetn(resetn),
        .count(count_val)
    );
    // memory
    memory #(
        .fname("mem_test.hex")
    ) memory_i2 (
        .clk(clk),
        .mem_addr(count_val),
        .i_mem_data(32'b0),
        .mem_rw(1'b1),
        .o_mem_data(mem_out)
    );
    assign led = ~mem_out[5:0];  // 5 LSB
endmodule
