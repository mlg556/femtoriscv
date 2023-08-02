module cpu_tb ();

    reg clk = 0;

    cpu u0 (.clk(clk));

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        #1000 $finish;

    end

endmodule
