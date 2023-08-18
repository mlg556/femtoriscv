module memory #(
    parameter fname = "fib_ascii.hex"
) (
    input             clk,
    input      [ 6:0] i_mem_addr,
    input      [31:0] i_mem_data,
    input             i_mem_rw,       // low=>read : high=>write
    output reg [31:0] o_mem_data = 0  // data read from memory
);
    reg [31:0] MEM[0:256];  /* synthesis syn_ramstyle = "block_ram" */
    wire [29:0] addr = i_mem_addr[6:2];  // ignore two LSBs

    initial begin
        $readmemh(fname, MEM);
    end

    always @(posedge clk) begin
        // rw is high: write to addr
        if (i_mem_rw) MEM[addr] <= i_mem_data;
        // rw is low: set out
        else
            o_mem_data <= MEM[addr];
    end
endmodule

// module memory (
//     data_out,
//     data_in,
//     addr,
//     clk,
//     wre,
//     rst
// );
//     output [31:0] data_out;
//     input [31:0] data_in;
//     input [6:0] addr;
//     input clk, wre, rst;
//     reg [31:0] mem[0:127];  /* synthesis syn_ramstyle = "block_ram" */
//     reg [31:0] data_out;

//     initial $readmemh("fib_ascii.hex", mem);

//     always @(posedge clk or posedge rst)
//         if (rst) data_out <= 0;
//         else if (wre) data_out <= data_in;
//         else data_out <= mem[addr];
//     always @(posedge clk) if (wre) mem[addr] <= data_in;
// endmodule

