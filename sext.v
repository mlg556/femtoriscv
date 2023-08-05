module sext;

    // sign extend 8 bits to 32 bits
    function [31:0] sext_8(input [7:0] b);
        sext_8 = $signed({{24{b[7]}}, b[6:0]});
    endfunction

    // sign extend 16 bits to 32 bits
    function [31:0] sext_16(input [15:0] b);
        sext_16 = $signed({{16{b[15]}}, b[14:0]});
    endfunction


    wire signed [ 7:0] b = -8'd3;  // byte
    wire signed [15:0] h = -8'd3;  // half

    wire signed [31:0] b_sext = sext_8(b);
    wire signed [31:0] h_sext = sext_16(h);


    initial begin
        #1 $display("sext_8: (%0d)\nsext_16: (%0d)", b_sext, h_sext);
    end

    // wire [31:0] I_imm = {{21{instr[31]}}, instr[30:20]};

endmodule
