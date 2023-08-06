module cpu_tb ();

    reg clk = 0;
    reg resetn = 1;

    cpu u0 (
        .resetn(resetn),
        .clk(clk)
    );

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        #100 $finish;  // just in case

    end

endmodule
