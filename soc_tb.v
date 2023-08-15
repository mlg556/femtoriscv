module soc_tb ();

    reg clk = 0;
    wire [31:0] a0;
    wire [31:0] addr;
    wire [31:0] data;

    soc u0 (.clk(clk));

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("soc_tb.vcd");
        $dumpvars(0, soc_tb);

        #500 $finish;  // just in case

    end

endmodule
