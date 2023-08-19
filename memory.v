module memory (
    input        clk,
    input [ 6:0] i_addr,
    input [31:0] i_data,
    input        i_wre,   // low=>read : high=>write
    input        rst,

    output reg [31:0] o_data = 0  // data read from memory
);

    reg [31:0] MEM[0:512];  /* synthesis syn_ramstyle = "block_ram" */
    wire [4:0] addr = i_addr[6:2];  // ignore two LSBs

    initial $readmemh("store_ascii.hex", MEM);

    always @(posedge clk or posedge rst)
        if (rst) o_data <= 0;
        else if (i_wre) o_data <= i_data;
        else o_data <= MEM[addr];

    always @(posedge clk) if (i_wre) MEM[addr] <= i_data;

    // always @(posedge clk) begin
    //     // rw is high: write to addr
    //     if (i_wre) MEM[addr_lsb] <= i_data;
    //     // rw is low: set out
    //     else
    //         o_data <= MEM[addr_lsb];
    // end
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

