module memory_fpga_tb;

    reg clk = 0;
    reg resetn = 1;

    wire [5:0] led;

    memory_fpga u0 (
        .clk(clk),
        .resetn(resetn),
        .led(led)
    );

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("memory_fpga_tb.vcd");
        $dumpvars(0, memory_fpga_tb);

        #500 $finish;  // just in case

    end

endmodule
