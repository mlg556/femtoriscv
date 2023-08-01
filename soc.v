module cpu (
    input clk,
    input resetn,
    output reg [5:0] leds = 0
    //input RXD,
    //output TXD
);

    localparam N = 9;

    reg [5:0] mem[0:N];
    // init mem
    initial begin
        mem[0] = 6'b000001;
        mem[1] = 6'b000010;
        mem[2] = 6'b000100;
        mem[3] = 6'b001000;
        mem[4] = 6'b010000;
        mem[5] = 6'b100000;

        mem[6] = 6'b010000;
        mem[7] = 6'b001000;
        mem[8] = 6'b000100;
        mem[9] = 6'b000010;
    end

    reg [3:0] PC = 0;
    always @(posedge clk) begin
        leds <= mem[PC];
        PC   <= (!resetn || PC == N) ? 0 : (PC + 1);
    end
endmodule

module clk_div #(
    parameter N = 2
) (
    input  clk,
    output clk_out
);
    reg [N:0] counter = 0;

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    assign clk_out = counter[N];

endmodule

module soc (
    input clk,
    input btn1,
    output [5:0] leds
);
    wire clk_slow;

    clk_div #(
        .N(100)
    ) i0 (
        .clk(clk),
        .clk_out(clk_slow)
    );

    cpu i1 (
        .clk(clk_slow),
        .resetn(btn1),
        .leds(leds)
    );


endmodule
