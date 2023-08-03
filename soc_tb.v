module soc_tb ();

    reg clk = 0;
    reg reset = 1;

    SOC u0 (
        .clk(clk),
        .resetn(reset)
    );

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("soc_tb.vcd");
        $dumpvars(0, soc_tb);

        #100 $finish;

    end

endmodule
