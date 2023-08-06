module cpu (
    input clk,
    input resetn,

    output [31:0] x10

);

    // opcodes
    localparam OPC_REG = 7'b0110011;  // add, sub, xor ...
    localparam OPC_IMM = 7'b0010011;  // addi, xori, slli ...
    localparam OPC_JAL = 7'b1101111;  // jal
    localparam OPC_JALR = 7'b1100111;  // jalr
    localparam OPC_BRANCH = 7'b1100011;  // beq, bne ...
    localparam OPC_LUI = 7'b0110111;  // lui
    localparam OPC_AUIPC = 7'b0010111;  // auipc
    localparam OPC_LOAD = 7'b0000011;  // lb, lh ...
    localparam OPC_SYS = 7'b1110011;  // ebreak ... special system instructions


    reg [31:0] MEM[63:0];  // Memory, 256 bytes
    reg [31:0] RA[31:0];  // register array, 32 registers

    reg [31:0] instr;  // current instruction
    reg [31:0] PC;  // Program Counter

    assign x10 = RA[10];  // x10  (a0) is outed for visuals

    // to hold source registers
    // register are signed by default, so we use $unsigned() when instruction is u-variant.
    reg signed [31:0] rs1 = 0;
    reg signed [31:0] rs2 = 0;

    integer i;
    `include "mul.v"  // program file
    initial begin
        PC = 0;
        LOADMEM;  // loads memory file from mem.v
        instr = MEM[0];

        // zero all registers
        for (i = 0; i < 31; i++) begin
            RA[i] = 0;
        end

        //$monitor("PC: %0d | OPC: %b | x1: %0d, x2: %0d", PC, opcode, RA[1], RA[2]);

    end

    // there are 6 main types of instructions
    // R-Type: instructions using 3 register inputs: add, xor, mul etc
    // I-Type: instructions with IMMediates and Loads: addi, lw, jalr, slli
    // S-Type: Store instructions: sw, sb
    // B-Type: BRAnch instructions: beq, bge
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
    wire [31:0] U_imm = {instr[31], instr[30:12], {12{1'b0}}};  // left shifted
    wire [31:0] J_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    // I_type shift amount: I_imm[4:0]
    wire [ 4:0] shamt = rs2_idx;

    // Load/store instruction sign extensions etc

    wire [31:0] loadstore_addr = rs1 + I_imm;


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
            OPC_REG: begin
                // fetch source registers
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
                        if (funct7 == 7'h20) RA[rd_idx] = rs1 >>> rs2;  // sRA
                    end

                    3'h2: begin
                        if (funct7 == 7'h00) RA[rd_idx] = rs1 < rs2 ? 32'd1 : 32'd0;  // slt
                    end
                    3'h3: begin
                        if (funct7 == 7'h00)
                            RA[rd_idx] = ($unsigned(rs1) < $unsigned(rs2)) ? 32'd1 : 32'd0;  // sltu
                    end

                endcase
                PC = PC + 4;  // increment PC
            end

            OPC_IMM: begin
                // fetch source register rs1
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
                        if (funct7 == 7'h20) RA[rd_idx] = $signed(rs1) >>> shamt;  // sRAi
                    end
                    3'h2: RA[rd_idx] = (rs1 < $signed(I_imm)) ? 32'd1 : 32'd0;  // slti
                    3'h3:
                    RA[rd_idx] = ($unsigned(rs1) < $unsigned(I_imm)) ? 32'd1 : 32'd0;  // sltiu
                endcase
                PC = PC + 4;  // increment PC

            end

            OPC_JAL: begin  // jal
                RA[rd_idx] = PC + 4;
                PC = PC + J_imm;
            end

            OPC_JALR: begin  // jalr
                rs1 = RA[rs1_idx];

                RA[rd_idx] = PC + 4;
                PC = rs1 + I_imm;
            end

            OPC_BRANCH: begin
                rs1 = RA[rs1_idx];
                rs2 = RA[rs2_idx];

                // branch if condition is satisfied, else increment PC to next line
                case (funct3)
                    3'h0: PC = (rs1 == rs2) ? PC + B_imm : PC + 4;  // beq
                    3'h1: PC = (rs1 != rs2) ? PC + B_imm : PC + 4;  // bne
                    3'h4: PC = (rs1 < rs2) ? PC + B_imm : PC + 4;  // blt
                    3'h5: PC = (rs1 >= rs2) ? PC + B_imm : PC + 4;  // bge
                    3'h6: PC = ($unsigned(rs1) < $unsigned(rs2)) ? PC + B_imm : PC + 4;  // bltu
                    3'h7: PC = ($unsigned(rs1) >= $unsigned(rs2)) ? PC + B_imm : PC + 4;  // bgeu
                endcase
            end

            OPC_LUI: begin
                RA[rd_idx] = U_imm;
                PC = PC + 4;  // increment PC
            end

            OPC_AUIPC: begin
                RA[rd_idx] = PC + U_imm;
                PC = PC + 4;  // increment PC

            end

            OPC_LOAD: begin
                rs1 = RA[rs1_idx];

                case (funct3)
                    3'h0: RA[rd_idx] = MEM[rs1+I_imm][7:0];  // lb | load byte, 8 bits
                    3'h1: RA[rd_idx] = MEM[rs1+I_imm][15:0];  // lh | load half, 16 bits
                    3'h2: RA[rd_idx] = MEM[rs1+I_imm][31:0];  // lw | load word, 32 bits
                    3'h4: RA[rd_idx] = MEM[rs1+I_imm][7:0];  // lb | load byte, 8 bits
                    3'h5: RA[rd_idx] = MEM[rs1+I_imm][7:0];  // lb | load byte, 8 bits
                endcase
                PC = PC + 4;  // increment PC

            end

            OPC_SYS: begin
                // basically nop, do NOT increment PC and finish simulation
                // $finish;
            end

        endcase
        instr = MEM[PC[31:2]];  // update for some reason
    end

endmodule
