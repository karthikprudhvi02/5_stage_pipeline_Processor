module test_simple_risc;
     
   reg clk1, clk2;
   integer k;
  
   simple_risc RISC (clk1,clk2);

   initial
     begin
       clk1 = 0;
       clk2 = 0;
       repeat(20)
         begin
           #5 clk1 = 1;  #5 clk1 = 0;    //Here this is for generating two phase clock
           #5 clk2 = 1;  #5 clk2 = 0; 
         end
     end
  
   initial
     begin
       for (k=0; k<31; k = k + 1)
         RISC.Register_Bank[k] = k;
       
       
       RISC.Memory[0] = 32'h4cc10005;   // mov r3,5
       RISC.Memory[1] = 32'h4c410004;   // movr1,4
       RISC.Memory[2] = 32'h61dc0000;   // dummy instruction to avoid hazard or r7,r7,r7
       RISC.Memory[3] = 32'h24850002;   // mod r2,r1,2
       RISC.Memory[4] = 32'h61dc0000;   // dummy instruction or r7,r7,r7
       RISC.Memory[5] = 32'h2c090000;   // cmp r2,0
       RISC.Memory[6] = 32'h61dc0000;   // dummy instruction
       RISC.Memory[7] = 32'h61dc0000;   // dummy instruction
       RISC.Memory[8] = 32'h80000001;   // beq loop
       RISC.Memory[9] = 32'h4cc10000;   // mov r3,0
       RISC.Memory[10] = 32'h61dc0000;  // dummy instruction
       RISC.Memory[11] = 32'h4d010001;  // loop : mov r4,1
       RISC.Memory[12] = 32'h61dc0000;   // dummy instruction
       
       RISC.Memory[13] = 32'hf8000000;   //hlt
 
       RISC.HALTED = 0;
       RISC.PC = 0;
       RISC.BRANCH_TAKEN = 0;
 
       
       #280
       for (k=1; k<5; k = k + 1)
         $display("R%1d - %2d", k, RISC.Register_Bank[k]);
         //$monitor("Condition : %1d", RISC.EX_MEM_Condition);
     end
   initial
     begin
       $dumpfile ("RISC.vcd");
       $dumpvars (0,test_simple_risc);
       #300  $finish;
     end
endmodule
