module counter #(
    parameter INC = 1
) (
    input clk,
    input resetn,
    output reg [31:0] count = 0
);

    always @(posedge clk) begin
        if (!resetn) begin
            count <= 0;
        end else begin
            count <= count + INC;
        end
    end

endmodule
