module memory (
    input             clk,
    input      [31:0] mem_addr,
    input      [31:0] i_mem_data,
    input             mem_rw,      // low=>read : high=>write
    output reg [31:0] o_mem_data   // data read from memory
);
    reg [31:0] MEM[0:255];  /* synthesis syn_ramstyle = "block_ram" */
    wire [31:0] addr = mem_addr[31:2];

    localparam fname = "load_ascii.hex";

    initial begin
        $readmemh(fname, MEM);
    end

    always @(posedge clk) begin
        // rw is high: write to addr
        if (mem_rw) MEM[addr] <= i_mem_data;
        // rw is low: set out
        else
            o_mem_data <= MEM[addr];
    end
endmodule
