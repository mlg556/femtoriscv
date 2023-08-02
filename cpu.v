module cpu (
    input clk
);

    localparam OPCODE_R = 7'b0110011;
    localparam OPCODE_I = 7'b0010011;


    reg [31:0] MEM[0:255];
    reg [31:0] PC = 0;
    reg [31:0] instr;

    reg [31:0] RA[0:31];  // register array

    reg [31:0] rs1 = 0;
    reg [31:0] rs2 = 0;


    `include "riscv_assembly.v"
    initial begin
        ADD(x0, x0, x0);
        ADD(x1, x0, x0);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADDI(x1, x1, 1);
        ADD(x2, x1, x0);
        ADD(x3, x1, x2);
        EBREAK();

        // zero all registers
        for (integer i = 0; i < 31; i++) begin
            RA[i] = 0;
        end

        $monitor("x1: %d, x2: %d", RA[1], RA[2]);
    end

    // there are 6 main types of instructions
    // R-Type: instructions using 3 register inputs: add, xor, mul etc
    // I-Type: instructions with IMMediates and Loads: addi, lw, jalr, slli
    // S-Type: Store instructions: sw, sb
    // B-Type: Branch instructions: beq, bge
    // U-Type: instructions using upper immediates (20-bits):  lui, auipc
    // J-Type: jump instructions: ja

    // R-Type fields
    wire [ 6:0] opcode = instr[6:0];
    wire [ 4:0] rd_idx = instr[11:7];
    wire [ 4:0] rs1_idx = instr[19:15];
    wire [ 4:0] rs2_idx = instr[24:20];
    wire [ 2:0] funct3 = instr[14:12];
    wire [ 6:0] funct7 = instr[31:25];

    // I-Type fields
    wire [11:0] I_imm = instr[32:20];

    // how to make x0 (RA[0]) always 0, even when written to?

    always @(posedge clk) begin
        instr = MEM[PC];
        RA[0] = 0;  // zero register


        case (opcode)
            OPCODE_R: begin
                rs1 = RA[rs1_idx];
                rs2 = RA[rs2_idx];

                case (funct3)
                    3'h0: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 + rs2;  // add
                        if (funct7 == 7'h20) RA[rd_idx] = rs1 - rs2;  // sub
                    end
                    3'h4: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 ^ rs2;  // xor
                    end

                    3'h6: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 | rs2;  // or
                    end

                    3'h7: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 & rs2;  // and
                    end

                    3'h1: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 << rs2;  // sll
                    end

                    3'h5: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 >> rs2;  // sll
                    end

                endcase

            end

            OPCODE_I: begin
                rs1 = RA[rs1_idx];
                case (funct3)
                    3'h0: RA[rd_idx] = rs1 + I_imm;  // addi
                    3'h4: RA[rd_idx] = rs1 ^ I_imm;  // xori
                    3'h6: RA[rd_idx] = rs1 | I_imm;  // ori
                    3'h7: RA[rd_idx] = rs1 & I_imm;  // andi
                endcase
            end
        endcase
        PC = PC + 1;
    end


endmodule
