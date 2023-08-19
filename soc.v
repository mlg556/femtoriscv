`include "memory.v"

module cpu (
    input clk,
    input i_resetn,

    input [31:0] i_mem_rdata,

    output reg [31:0] o_mem_wdata = 0,
    output reg [31:0] o_mem_addr = 0,

    output reg o_mem_rw = 0,

    output signed [31:0] a0

);

    localparam K = 32;

    // sign extend 8 => 32
    function [(K-1):0] sext8(input [(N-1):0] b);
        localparam N = 8;
        sext8 = $signed({{(K - N) {b[(N-1)]}}, b[(N-2):0]});
    endfunction

    // sign extend 12 => 32
    function [(K-1):0] sext12(input [(N-1):0] b);
        localparam N = 12;
        sext12 = $signed({{(K - N) {b[(N-1)]}}, b[(N-2):0]});
    endfunction

    // sign extend 16 => 32
    function [(K-1):0] sext16(input [(N-1):0] b);
        localparam N = 16;
        sext16 = $signed({{(K - N) {b[(N-1)]}}, b[(N-2):0]});
    endfunction

    // sign extend 20 => 32
    function [(K-1):0] sext20(input [(N-1):0] b);
        localparam N = 20;
        sext20 = $signed({{(K - N) {b[(N-1)]}}, b[(N-2):0]});
    endfunction


    // halfword and byte extractions for LOAD
    wire [15:0] mem_rdata_h = o_mem_addr[1] ? i_mem_rdata[31:16] : i_mem_rdata[15:0];
    wire [ 7:0] mem_rdata_b = o_mem_addr[0] ? mem_rdata_h[15:8] : mem_rdata_h[7:0];

    // opcodes
    localparam OPC_REG = 7'b0110011;  // add, sub, xor ... rd = rs1 op rs2
    localparam OPC_IMM = 7'b0010011;  // addi, xori, slli ... rd = rs1 op imm
    localparam OPC_JAL = 7'b1101111;  // jal: jump and link
    localparam OPC_JALR = 7'b1100111;  // jalr: jump and link register
    localparam OPC_BRANCH = 7'b1100011;  // beq, bne ... branch if equal/notequal
    localparam OPC_LUI = 7'b0110111;  // lui: load upper immediate
    localparam OPC_AUIPC = 7'b0010111;  // auipc: add upper immediate to pc
    localparam OPC_LOAD = 7'b0000011;  // lb, lh ... load from memory
    localparam OPC_STORE = 7'b0100011;  // sb, sh, sw... store in memory
    localparam OPC_SYS = 7'b1110011;  // ebreak ... special system instructions


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
        //$monitor("a0: %d", a0);
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
    wire [31:0] I_imm = sext12(instr[31:20]);
    wire [31:0] S_imm = sext12({instr[31:25], instr[11:7]});
    wire [31:0] B_imm = sext12({instr[31], instr[7], instr[30:25], instr[11:8], 1'b0});
    wire [31:0] U_imm = {instr[31:12], {12{1'b0}}};
    wire [31:0] J_imm = sext20({instr[31], instr[19:12], instr[20], instr[30:21], 1'b0});

    // I_type shift amount: I_imm[4:0]
    wire [ 4:0] shamt = rs2_idx;

    // store/load addresses
    reg  [31:0] store_addr;
    reg  [31:0] load_addr;
    // wire [31:0] store_addr = rs1 + S_imm;
    // wire [31:0] load_addr = rs1 + I_imm;

    // The state machine
    localparam FETCH_INSTR = 0;
    localparam WAIT_INSTR = 1;
    localparam EXECUTE = 2;
    localparam WAIT_LOAD = 3;
    localparam LOAD = 4;
    localparam WAIT_STORE = 5;
    localparam STORE = 6;
    localparam END_STORE = 7;

    reg [4:0] state = FETCH_INSTR;

    always @(posedge clk) begin
        // RESET
        if (!i_resetn) begin
            PC = 0;
            state = FETCH_INSTR;
        end
        // force zero register (x0)
        RA[0] = 0;

        // memory read mode by default
        //o_mem_rw = 0;

        // clock cycle state machine
        case (state)
            FETCH_INSTR: begin
                state = WAIT_INSTR;
            end
            WAIT_INSTR: begin
                instr = i_mem_rdata;
                state = EXECUTE;
            end
            EXECUTE: begin
                //$display("OPC: %b", opcode);
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
                        o_mem_addr <= PC;
                        state = FETCH_INSTR;
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
                                if (funct7 == 7'h20) RA[rd_idx] = $signed(rs1) >>> shamt;  // srai
                            end
                            3'h2: RA[rd_idx] = (rs1 < $signed(I_imm)) ? 32'd1 : 32'd0;  // slti
                            3'h3:
                            RA[rd_idx] = ($unsigned(rs1) < $unsigned(I_imm)) ? 32'd1 :
                                32'd0;  // sltiu
                        endcase
                        PC = PC + 4;  // increment PC
                        o_mem_addr <= PC;
                        state = FETCH_INSTR;
                    end

                    OPC_JAL: begin  // jal
                        RA[rd_idx] = PC + 4;
                        PC = PC + J_imm;
                        o_mem_addr <= PC;
                        state = FETCH_INSTR;
                    end

                    OPC_JALR: begin  // jalr
                        rs1 = RA[rs1_idx];
                        RA[rd_idx] = PC + 4;

                        PC = rs1 + I_imm;
                        o_mem_addr <= PC;
                        state = FETCH_INSTR;
                    end

                    OPC_BRANCH: begin
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
                        o_mem_addr <= PC;
                        state = FETCH_INSTR;
                    end

                    OPC_LUI: begin
                        RA[rd_idx] = U_imm;
                        PC = PC + 4;  // increment PC
                        o_mem_addr <= PC;
                        state = FETCH_INSTR;
                    end

                    OPC_AUIPC: begin
                        RA[rd_idx] = PC + U_imm;
                        PC = PC + 4;  // increment PC

                        o_mem_addr <= PC;
                        state = FETCH_INSTR;

                    end

                    OPC_LOAD: begin
                        rs1 = RA[rs1_idx];

                        o_mem_addr = rs1 + I_imm;
                        PC = PC + 4;

                        o_mem_rw = 0;
                        state = WAIT_LOAD;
                    end

                    OPC_STORE: begin
                        rs1 = RA[rs1_idx];
                        rs2 = RA[rs2_idx];
                        o_mem_addr = rs1 + S_imm;
                        PC = PC + 4;
                        o_mem_rw = 1;

                        case (funct3)
                            3'h2: o_mem_wdata = rs2;  // sw: store word
                        endcase

                        state = WAIT_STORE;

                    end

                    OPC_SYS: begin
                        // basically nop, do NOT increment PC and finish simulation
                        //$finish;
                    end
                endcase
            end
            WAIT_LOAD:  state = LOAD;
            LOAD: begin
                // we need to sign-extend the 8 and 16 bits.
                // zero-extension is done automagically by verilog in assignment.
                case (funct3)
                    3'h0: RA[rd_idx] = sext8(mem_rdata_b);  // lb
                    3'h1: RA[rd_idx] = sext16(mem_rdata_h);  // lh
                    3'h2: RA[rd_idx] = i_mem_rdata;  // lw | load word, 32 bits
                    3'h4: RA[rd_idx] = mem_rdata_b;  // lbu
                    3'h5: RA[rd_idx] = mem_rdata_h;  // lhu
                endcase

                //$display("LOAD: RA[%d] = MEM[%0d]", rd_idx, o_mem_addr[31:2]);

                o_mem_addr <= PC;
                state = FETCH_INSTR;
            end
            WAIT_STORE: state = STORE;
            STORE: begin

                //$display("STORE: MEM[%0d] = RA[%d] (%0d)", o_mem_addr[31:2], rs2_idx, o_mem_wdata);

                o_mem_rw = 0;
                o_mem_addr <= PC;
                state = FETCH_INSTR;
            end

        endcase
    end

endmodule


module soc (
    input clk,
    input btn1,

    output [5:0] led
);
    // initial $monitor("a0: %d", a0);
    wire [31:0] cpu_out_mem_in_data;
    wire [31:0] cpu_in_mem_out_data;
    wire [31:0] wire_addr;
    wire [6:0] wire_addr_lsb;
    wire wire_mem_rw;

    wire [31:0] wire_led;
    // cpu
    cpu cpu_i0 (
        .clk(clk),

        .i_mem_rdata(cpu_in_mem_out_data),
        .i_resetn(btn1),

        .o_mem_wdata(cpu_out_mem_in_data),
        .o_mem_addr(wire_addr),
        .o_mem_rw(wire_mem_rw),
        .a0(wire_led)
    );

    assign wire_addr_lsb = wire_addr[6:0];

    // memory
    memory memory_i1 (
        .clk(clk),

        .i_addr(wire_addr_lsb),
        .i_data(cpu_out_mem_in_data),
        .i_wre(wire_mem_rw),
        .rst(1'b0),

        .o_data(cpu_in_mem_out_data)
    );

    assign led = wire_led[5:0];

    // assign addr = wire_addr;
    // assign data = wire_data;
endmodule
