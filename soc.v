module memory (
    input             clk,
    input      [31:0] mem_addr,
    input      [31:0] i_mem_data,
    input             mem_rw,      // low=>write : high=>read
    output reg [31:0] o_mem_data   // data read from memory
);
    reg [31:0] MEM[0:255];  /* synthesis syn_ramstyle = "block_ram" */
    wire [31:0] addr = mem_addr[31:2];

    localparam fname = "fib_ascii.hex";

    initial begin
        $readmemh(fname, MEM);
    end

    always @(posedge clk) begin
        if (mem_rw) o_mem_data <= MEM[addr];
        else MEM[addr] <= i_mem_data;
    end
endmodule

module cpu (
    input clk,
    input resetn,

    input [31:0] mem_rdata,
    output reg [31:0] mem_addr,

    output [31:0] a0

);

    // opcodes
    localparam OPC_R = 7'b0110011;
    localparam OPC_I = 7'b0010011;
    localparam OPC_ILOAD = 7'b0000011;
    localparam OPC_JAL = 7'b1101111;
    localparam OPC_JALR = 7'b1100111;
    localparam OPC_B = 7'b1100011;
    localparam OPC_LUI = 7'b0110111;
    localparam OPC_AUIPC = 7'b0010111;
    localparam OPC_SYS = 7'b1110011;  // special system instruction


    reg [31:0] PC = 0;
    reg [31:0] instr = 0;

    reg [31:0] RA[0:31];  // register array
    assign a0 = RA[10];  // a0  (a0) is outed for visuals

    // to hold source registers
    // register are signed by default, so we use $unsigned() when instruction is u-variant.
    reg signed [31:0] rs1 = 0;
    reg signed [31:0] rs2 = 0;

    integer i;
    initial begin
        PC = 0;
        // zero all registers
        for (i = 0; i < 31; i++) begin
            RA[i] = 0;
        end
        $monitor("a0: %d", a0);
        //$monitor("PC: %d", PC);
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
    wire [31:0] U_imm = {instr[31], instr[30:12], {12{1'b0}}};  // left shifted
    wire [31:0] J_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

    // I_type shift amount: I_imm[4:0]
    wire [ 4:0] shamt = rs2_idx;

    // The state machine
    localparam FETCH_INSTR = 0;
    localparam WAIT_INSTR = 1;
    localparam EXECUTE = 2;
    reg [1:0] state = FETCH_INSTR;

    always @(posedge clk) begin
        // RESET
        if (!resetn) begin
            PC = 0;
            state = FETCH_INSTR;
        end
        // force zero register (x0)
        RA[0] = 0;

        // clock cycle state machine
        case (state)
            FETCH_INSTR: state = WAIT_INSTR;
            WAIT_INSTR: begin
                instr = mem_rdata;
                state = EXECUTE;
            end
            EXECUTE: begin
                // $display("OPC: %b", opcode);
                case (opcode)
                    OPC_R: begin
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
                                if (funct7 == 7'h20) RA[rd_idx] = rs1 >>> rs2;  // sra
                            end

                            3'h2: begin
                                if (funct7 == 7'h00) RA[rd_idx] = rs1 < rs2 ? 32'd1 : 32'd0;  // slt
                            end
                            3'h3: begin
                                if (funct7 == 7'h00)
                                    RA[rd_idx] = ($unsigned(
                                        rs1
                                    ) < $unsigned(
                                        rs2
                                    )) ? 32'd1 : 32'd0;  // sltu
                            end

                        endcase
                        PC = PC + 4;  // increment PC
                    end

                    OPC_I: begin
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
                                if (funct7 == 7'h20) RA[rd_idx] = $signed(rs1) >>> shamt;  // srai
                            end
                            3'h2: RA[rd_idx] = (rs1 < $signed(I_imm)) ? 32'd1 : 32'd0;  // slti
                            3'h3:
                            RA[rd_idx] = ($unsigned(rs1) < $unsigned(I_imm)) ? 32'd1 :
                                32'd0;  // sltiu
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

                    OPC_B: begin
                        rs1 = RA[rs1_idx];
                        rs2 = RA[rs2_idx];

                        case (funct3)
                            3'h0: PC = (rs1 == rs2) ? PC + B_imm : PC + 4;  // beq
                            3'h1: PC = (rs1 != rs2) ? PC + B_imm : PC + 4;  // bne
                            3'h4: PC = (rs1 < rs2) ? PC + B_imm : PC + 4;  // blt
                            3'h5: PC = (rs1 >= rs2) ? PC + B_imm : PC + 4;  // bge
                            3'h6:
                            PC = ($unsigned(rs1) < $unsigned(rs2)) ? PC + B_imm : PC + 4;  // bltu
                            3'h7:
                            PC = ($unsigned(rs1) >= $unsigned(rs2)) ? PC + B_imm : PC + 4;  // bgeu
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

                    OPC_SYS: begin
                        // basically nop, do NOT increment PC and finish simulation
                        // $finish;
                    end
                endcase

                // update addr
                mem_addr = PC;
                // reset state
                state = FETCH_INSTR;
            end
        endcase
    end

endmodule

module soc (
    input clk,
    output [31:0] a0,
    output [31:0] addr,
    output [31:0] data
);
    wire [31:0] wire_data;
    wire [31:0] wire_addr;
    // cpu
    cpu cpu_i0 (
        .mem_rdata(wire_data),
        .resetn(1'b1),
        .clk(clk),
        .mem_addr(wire_addr),
        .a0(a0)
    );
    // memory
    memory memory_i1 (
        .mem_addr(wire_addr),
        .i_mem_data(32'b0),
        .mem_rw(1'b1),
        .clk(clk),
        .o_mem_data(wire_data)
    );

    assign addr = wire_addr;
    assign data = wire_data;
endmodule
