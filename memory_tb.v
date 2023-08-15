module memory_tb;

    reg clk = 0;
    reg mem_rw = 1;
    reg [31:0] mem_addr = 0;
    reg [31:0] i_mem_data = 0;

    wire [31:0] o_mem_data;

    memory u0 (
        .clk(clk),
        .mem_addr(mem_addr),
        .mem_rw(mem_rw),
        .i_mem_data(i_mem_data),
        .o_mem_data(o_mem_data)
    );

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("memory_tb.vcd");
        $dumpvars(0, memory_tb);

        //$monitor("%d => %x", mem_addr, mem_data);

        #2 mem_addr = 0;

        for (integer i = 0; i < 16; i++) begin
            // $display("%d => %x", mem_addr, o_mem_data);
            #2 mem_addr = mem_addr + 4;

        end
        $finish;
    end





endmodule
