module memory (
    input             clk,
    input      [31:0] mem_addr,
    input      [31:0] i_mem_data,
    input             mem_rw,      // low=>write : high=>read
    output reg [31:0] o_mem_data   // data read from memory
);
    reg [31:0] MEM[0:255];  /* synthesis syn_ramstyle = "block_ram" */
    wire [31:0] addr = mem_addr[31:2];

    localparam fname = "load_ascii.hex";

    initial begin
        $readmemh(fname, MEM);
    end

    always @(posedge clk) begin
        if (mem_rw) o_mem_data = MEM[addr];
        else MEM[addr] = i_mem_data;
    end
endmodule
