module simple_risc(clk1,clk2);
    input clk1 , clk2;
    reg [31:0] PC, InF_InD_InR, InF_InD_NewPC;
    reg [31:0] InD_EX_InR, InD_EX_NewPC, InD_EX_A, InD_EX_B, InD_EX_Imm;
    reg [2:0]  InD_EX_type, EX_MEM_type, MEM_WB_type;
    reg [31:0] MEM_WB_InR, MEM_WB_ALUout, MEM_WB_LMD;
    reg [31:0] EX_MEM_InR, EX_MEM_ALUout, EX_MEM_B, EX_MEM_A;
    reg        EX_MEM_Condition;
  

    reg [31:0] Register_Bank [0:15];
    reg [31:0] Memory        [0:1023];
    
    
    parameter ADD = 5'b00000, SUB = 5'b00001, MUL = 5'b00010, DIV = 5'b00011, MOD = 5'b00100, AND = 5'b00101, NOT = 5'b00110, LD = 5'b00111, ST = 5'b01000, CMP = 5'b01001, BEQ = 5'b01010,
                    BGT = 5'b01011, MOV = 5'b01100, LSL = 5'b01101, LSR = 5'b01110, OR = 5'b01111,HLT = 5'b10000;
    
   
    parameter RR_ALU = 3'b000, RI_ALU = 3'b001, LOAD = 3'b010, STORE = 3'b011, BRANCH = 3'b100, HALT = 3'b101, COMPARE = 3'b110;

   
    

    reg HALTED;
    
    reg BRANCH_TAKEN;
   
    always @(posedge clk1)                            // First stage which is Instruction fetching
          if(HALTED == 0)
          begin
             if(((EX_MEM_InR[31:27] == BEQ) && (EX_MEM_Condition == 1))||((EX_MEM_InR[31:27] == BGT) && (EX_MEM_Condition == 0)))
                 begin
                    InF_InD_InR    <= #2 Memory[EX_MEM_ALUout];     // From instruction memory instruction is sent to instruction register
                    BRANCH_TAKEN   <= #2 1'b1;
                    InF_InD_NewPC  <= #2 EX_MEM_ALUout + 1;        // Here,+ 1 id=s because I increment the value of PC which address to the instruction not the word that's why I make pc+1
                    PC             <= #2 EX_MEM_ALUout + 1;
                 end
             else
               begin
                   InF_InD_InR     <= #2 Memory[PC];
                   InF_InD_NewPC   <= #2 PC + 1;
                   PC              <= #2 PC + 1;
               end
    end 
    
    always @(posedge clk2)                          //Second Stage
                                                    // I used 2 clocks which are in alternated which should not coincide
        if (HALTED  == 0)
        begin
          if(InF_InD_InR[21:18]   == 4'b0000)   InD_EX_A <= 0;
          
          else InD_EX_A <= #2 Register_Bank[InF_InD_InR[21:18]];
         
          if(InF_InD_InR[17:14]  == 4'b0000)    InD_EX_B  <= 0;
          else InD_EX_B <= #2 Register_Bank[InF_InD_InR[17:14]];
      
          InD_EX_NewPC    <= #2 InF_InD_NewPC;
          InD_EX_InR      <= #2 InF_InD_InR;
          InD_EX_Imm      <= #2 {{16{InF_InD_InR[15]}},{InF_InD_InR[15:0]}};
          

          case (InF_InD_InR[31:27])
             
             ADD,SUB,MUL,DIV,MOD,AND,OR,LSL,LSR,MOV,NOT:        begin
                                                                  if(InF_InD_InR[26] == 1'b0)  InD_EX_type  <=  #2 RR_ALU;
                                                                  else  InD_EX_type  <=  #2 RI_ALU;
                                                                end
             LD:                                                InD_EX_type  <=  #2 LOAD;
             ST:                                                InD_EX_type  <=  #2 STORE;
             CMP:                                               InD_EX_type  <=  #2 COMPARE;
             BEQ,BGT:                                           InD_EX_type  <=  #2 BRANCH;
             HLT:                                               InD_EX_type  <=  #2 HALT;
             default:                                           InD_EX_type  <=  #2 HALT;
           
          endcase
    end
    
    always @(posedge clk1)
          if (HALTED  == 0)
          begin
            EX_MEM_type  <= #2 InD_EX_type;
            EX_MEM_InR   <= #2 InD_EX_InR;
            BRANCH_TAKEN <= #2 0;
     
          case (InD_EX_type)
            RR_ALU:  begin
                       case (InD_EX_InR[31:27])
                         ADD:     EX_MEM_ALUout  <= #2 InD_EX_A + InD_EX_B;
                         SUB:     EX_MEM_ALUout  <= #2 InD_EX_A - InD_EX_B;
                         MUL:     EX_MEM_ALUout  <= #2 InD_EX_A * InD_EX_B;
                         DIV:     EX_MEM_ALUout  <= #2 InD_EX_A / InD_EX_B;
                         MOV:     EX_MEM_ALUout  <= #2 InD_EX_B;
                         MOD:     EX_MEM_ALUout  <= #2 InD_EX_A % InD_EX_B;
                         AND:     EX_MEM_ALUout  <= #2 InD_EX_A & InD_EX_B;
                         OR:      EX_MEM_ALUout  <= #2 InD_EX_A | InD_EX_B;
                         NOT:     EX_MEM_ALUout  <= #2 ~InD_EX_B;
                         LSL:     EX_MEM_ALUout  <= #2 InD_EX_A << InD_EX_B;
                         LSR:     EX_MEM_ALUout  <= #2 InD_EX_A >> InD_EX_B;
                         default: EX_MEM_ALUout  <= #2 32'hxxxxxxxx;
                       endcase
                     end
            
            RI_ALU:  begin
                       case (InD_EX_InR[31:27])
                         ADD:     EX_MEM_ALUout  <= #2 InD_EX_A + InD_EX_Imm;
                         SUB:     EX_MEM_ALUout  <= #2 InD_EX_A - InD_EX_Imm;
                         MUL:     EX_MEM_ALUout  <= #2 InD_EX_A * InD_EX_Imm;
                         DIV:     EX_MEM_ALUout  <= #2 InD_EX_A / InD_EX_Imm;
                         MOV:     EX_MEM_ALUout  <= #2 InD_EX_Imm;
                         MOD:     EX_MEM_ALUout  <= #2 InD_EX_A % InD_EX_Imm;
                         AND:     EX_MEM_ALUout  <= #2 InD_EX_A & InD_EX_Imm;
                         OR:      EX_MEM_ALUout  <= #2 InD_EX_A | InD_EX_Imm;
                         NOT:     EX_MEM_ALUout  <= #2 ~InD_EX_Imm;
                         LSL:     EX_MEM_ALUout  <= #2 InD_EX_A << InD_EX_Imm;
                         LSR:     EX_MEM_ALUout  <= #2 InD_EX_A >> InD_EX_Imm;
                         default: EX_MEM_ALUout  <= #2 32'hxxxxxxxx;
                       endcase
                     end     
 
             LOAD,STORE: begin
                           EX_MEM_ALUout  <= #2 InD_EX_A + InD_EX_Imm;
                           EX_MEM_B       <= #2 InD_EX_B;
                           EX_MEM_A       <= #2 InD_EX_A;
                         end
             COMPARE:   begin
                          case(InD_EX_type)
                          RR_ALU:  begin
                                       if(InD_EX_A == InD_EX_B)  EX_MEM_Condition <= #2 1'b1;
                                       if(InD_EX_A > InD_EX_B)   EX_MEM_Condition <= #2 1'b0;
                                   end
                          RI_ALU:  begin
                                       if(InD_EX_A == InD_EX_Imm)  EX_MEM_Condition <= #2 1'b1;
                                       if(InD_EX_A > InD_EX_Imm)   EX_MEM_Condition <= #2 1'b0;
                                   end
                          endcase
                        end
             BRANCH:   begin
                         EX_MEM_ALUout <= #2 InD_EX_NewPC + InD_EX_Imm;
                       end
       
          endcase
    end
    
    always @(posedge clk2)
       if(HALTED == 0)
       begin
         MEM_WB_type  <= #2 EX_MEM_type;
         MEM_WB_InR   <= #2 EX_MEM_InR;
 
         case (EX_MEM_type)
           RR_ALU,RI_ALU:  MEM_WB_ALUout <= #2 EX_MEM_ALUout;
           LOAD:           MEM_WB_LMD    <= #2 Memory[EX_MEM_ALUout];
           STORE:          if(BRANCH_TAKEN == 0)  Memory[EX_MEM_ALUout]  <= #2 Register_Bank[EX_MEM_InR[25:22]];
         endcase
    end
 

    always @(posedge clk1)
       begin
         if(BRANCH_TAKEN == 0)
         case (MEM_WB_type)
           RR_ALU,RI_ALU:   Register_Bank[MEM_WB_InR[25:22]]   <= #2 MEM_WB_ALUout;
           LOAD:            Register_Bank[MEM_WB_InR[25:22]]   <= #2 MEM_WB_LMD;
           HALT:            HALTED <= #2 1'b1;
         endcase
       end
endmodule
