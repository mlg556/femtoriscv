module cpu (
    input clk,
    input resetn
);

    // opcodes
    localparam TYPE_R = 7'b0110011;
    localparam TYPE_I = 7'b0010011;
    localparam TYPE_ILOAD = 7'b0000011;
    localparam TYPE_JAL = 7'b1101111;
    localparam TYPE_JALR = 7'b1100111;

    localparam TYPE_X = 7'b1110011;  // special system instruction


    reg [31:0] MEM[0:255];
    reg [31:0] PC = 0;
    reg [31:0] instr;

    reg [31:0] RA[0:31];  // register array

    // to hgold source registers
    reg [31:0] rs1 = 0;
    reg [31:0] rs2 = 0;


    `include "riscv_assembly.v"
    integer L0_ = 4;
    integer i;
    initial begin
        PC     = 0;

        MEM[0] = 32'h000000b3;
        MEM[1] = 32'h00108093;
        MEM[2] = 32'hffdff06f;

        // zero all registers
        for (i = 0; i < 31; i++) begin
            RA[i] = 0;
        end

        instr = MEM[0];


        //$monitor("PC: %0d | OPC: %b | x1: %0d, x2: %0d", PC, opcode, RA[1], RA[2]);
    end

    // there are 6 main types of instructions
    // R-Type: instructions using 3 register inputs: add, xor, mul etc
    // I-Type: instructions with IMMediates and Loads: addi, lw, jalr, slli
    // S-Type: Store instructions: sw, sb
    // B-Type: Branch instructions: beq, bge
    // U-Type: instructions using upper immediates (20-bits):  lui, auipc
    // J-Type: jump instructions: ja

    // common fields
    wire [ 6:0] opcode = instr[6:0];
    wire [ 4:0] rd_idx = instr[11:7];
    wire [ 4:0] rs1_idx = instr[19:15];
    wire [ 4:0] rs2_idx = instr[24:20];
    wire [ 2:0] funct3 = instr[14:12];
    wire [ 6:0] funct7 = instr[31:25];

    // immediate fields
    wire [31:0] I_imm = {{21{instr[31]}}, instr[30:20]};
    wire [31:0] S_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    wire [31:0] B_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] U_imm = {instr[31], instr[30:12], {12{1'b0}}};
    wire [31:0] J_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    // I_type shamt: I_imm[4:0]
    wire [ 4:0] shamt = rs2_idx;

    always @(posedge clk) begin
        // RESET
        if (!resetn) begin
            PC = 0;
        end
        // fetch instruction
        instr = MEM[PC[31:2]];

        // force zero register (x0)
        RA[0] = 0;
        case (opcode)
            TYPE_R: begin
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
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 >> rs2;  // srl
                        if (funct7 == 7'h20) RA[rd_idx] = $signed(rs1) >>> $signed(rs2);  // sra?
                    end

                    3'h2: begin
                        if (funct7 == 7'h00)
                            RA[rd_idx] = ($signed(rs1) < $signed(rs2)) ? 32'd1 : 32'd0;  // slt?
                    end
                    3'h3: begin
                        if (funct7 == 7'h00) RA[rd_idx] = (rs1 < rs2) ? 32'd1 : 32'd0;  // sltu
                    end

                endcase
                //increment PC
                PC = PC + 4;
            end

            TYPE_I: begin
                rs1 = RA[rs1_idx];
                case (funct3)
                    3'h0: RA[rd_idx] = rs1 + I_imm;  // addi
                    3'h4: RA[rd_idx] = rs1 ^ I_imm;  // xori
                    3'h6: RA[rd_idx] = rs1 | I_imm;  // ori
                    3'h7: RA[rd_idx] = rs1 & I_imm;  // andi
                    3'h1: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 << shamt;  // slli
                    end
                    3'h5: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 >> shamt;  // srli
                        if (funct7 == 7'h20) RA[rd_idx] = $signed(rs1) >>> shamt;  // srai
                    end
                    3'h2: RA[rd_idx] = ($signed(rs1) < $signed(I_imm)) ? 32'd1 : 32'd0;  // slti
                    3'h3: RA[rd_idx] = (rs1 < I_imm) ? 32'd1 : 32'd0;  // sltiu
                endcase
                // increment PC
                PC = PC + 4;
            end

            TYPE_JAL: begin
                RA[rd_idx] = PC + 4;
                PC = PC + J_imm;
            end

            TYPE_JALR: begin
                rs1 = RA[rs1_idx];

                RA[rd_idx] = PC + 4;
                PC = rs1 + I_imm;
            end

            // TYPE_X: begin
            //     // basically nop, do NOT increment PC and finish simulation
            //     //$display("PC: %0d", PC);
            //     $finish;
            // end
        endcase

        instr = MEM[PC[31:2]];  // update opcode before next clock?
    end

endmodule
