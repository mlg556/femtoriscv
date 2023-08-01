module soc_tb ();
    reg clk = 0;
    reg btn1 = 1;
    wire [5:0] leds;

    soc uut (
        .clk (clk),
        .btn1(btn1),
        .leds(leds)
    );

    initial begin
        clk = 0;
    end

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("soc_tb.vcd");
        $dumpvars(0, soc_tb);
        $monitor("%b", leds);
        #500 $finish;
    end
endmodule
