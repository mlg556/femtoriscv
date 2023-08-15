module memory (
    input             clk,
    input      [31:0] mem_addr,
    input      [31:0] i_mem_data,
    input             mem_rw,      // low=>write : high=>read
    output reg [31:0] o_mem_data   // data read from memory
);
    reg [31:0] MEM[0:255];  /* synthesis syn_ramstyle = "block_ram" */

    wire [31:0] addr = mem_addr[31:2];

    initial begin
        //$readmemh(fname, MEM);
        // fib.v
        MEM[0] = 32'h00100313;
        MEM[1] = 32'h00100393;
        MEM[2] = 32'h00000e13;
        MEM[3] = 32'h00030513;
        MEM[4] = 32'h00730e33;
        MEM[5] = 32'h00030393;
        MEM[6] = 32'h000e0313;
        MEM[7] = 32'h00030513;
        MEM[8] = 32'hff1ff06f;
    end

    always @(posedge clk) begin
        if (mem_rw) o_mem_data <= MEM[addr];
        else MEM[addr] <= i_mem_data;
    end
endmodule
