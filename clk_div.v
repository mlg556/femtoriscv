module clkdiv (
    input  clk,
    output clk_out
);
    // slows down the clock by 2^N
    localparam N = 21;
    reg [N:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign clk_out = counter[N];

endmodule
