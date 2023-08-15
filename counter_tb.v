module counter_tb;

    reg clk = 0;
    reg resetn = 1;

    wire [31:0] count;

    counter #(
        .INC(4)
    ) u0 (
        .clk(clk),
        .resetn(resetn),
        .count(count)
    );

    always begin
        #1 clk = ~clk;
    end

    initial begin
        $dumpfile("counter_tb.vcd");
        $dumpvars(0, counter_tb);

        $monitor("%d", count);

        #20 $finish;
    end

endmodule
