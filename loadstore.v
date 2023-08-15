// OPC_LOAD: begin
//     // source register
//     rs1 = RA[rs1_idx];

//     // we need to sign-extend the 8 and 16 bits.
//     // zero-extension is done automagically by verilog in assignment.
//     case (funct3)
//         3'h0: RA[rd_idx] <= sext8(MEM[load_addr[31:2]][7:0]);  // lb
//         3'h1: RA[rd_idx] <= sext16(MEM[load_addr[31:2]][15:0]);  // lh
//         3'h2: RA[rd_idx] <= MEM[load_addr[31:2]];  // lw | load word, 32 bits
//         3'h4: RA[rd_idx] <= MEM[load_addr[31:2]][7:0];  // lbu
//         3'h5: RA[rd_idx] <= MEM[load_addr[31:2]][15:0];  // lhu
//     endcase
//     PC = PC + 4;  // increment PC

// end

// OPC_STORE: begin
//     // source registers
//     rs1 = RA[rs1_idx];
//     rs2 = RA[rs2_idx];

//     case (funct3)
//         3'h0: MEM[store_addr[31:2]][7:0] <= rs2[7:0];  // sb: store byte
//         3'h1: MEM[store_addr[31:2]][15:0] <= rs2[15:0];  // sh: store half
//         3'h2: MEM[store_addr[31:2]] <= rs2;  // sw: store word
//     endcase
//     // $display("STORE: MEM[%0d] <= %0d", store_addr[31:2], rs2);
//     PC = PC + 4;
// end
