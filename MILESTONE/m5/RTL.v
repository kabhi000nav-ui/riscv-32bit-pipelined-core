`timescale 1ns / 1ps
//---------------------------------------------------------------------------
//                                IF / ID
//---------------------------------------------------------------------------

//INSTRUCTION MEMORY
module instruction_memory(input [31:0]A , output [31:0]RD);
  
  reg [31:0] instruction_memory [0:1023];
  initial $readmemh("program.hex", instruction_memory);
  
  assign RD = instruction_memory [A[11:2]];       // to select which memory location we want.
endmodule

//PC
module pc(input [31:0] pc_next , 
		  input clk , Stall_F ,
		  output reg [31:0]pc_current );
	initial pc_current = 32'b0;
	
	always @(posedge clk) begin
		if(Stall_F != 1)
		    pc_current <= pc_next;
		else
			pc_current <= pc_current;
	end
	
endmodule

//PC + 4 ADDER
module pc_4adder(input [31:0]pc , output [31:0]pc4);
  
  assign pc4 = pc + 32'd4;
endmodule

// MUX3
module mux3(input [31:0] a , b , input PCsrc , output [31:0]pc_next);
  assign pc_next = PCsrc ? b : a;
endmodule

// PIPELINE REGISTER IF/ID
module IF_ID(input [31:0] instruction , PC , pc4 , 
			 input clk , reset , Stall_D , Flash_D ,
             output reg [31:0] instruction_D , PC_D , pc4_D);
             
    always @(posedge clk , posedge reset)begin
        if(reset) begin
		    instruction_D <= 32'b0;
		    PC_D          <= 32'b0;
		    pc4_D         <= 32'b0;
		end
		
		else if(Flash_D) begin
		    instruction_D <= 32'b0;
		    PC_D          <= 32'b0;
		    pc4_D         <= 32'b0;
		end
		
		else if(!Stall_D) begin
		    instruction_D <= instruction;
		    PC_D          <= PC;
			pc4_D         <= pc4;    
		end 
		
		else begin
			instruction_D <= instruction_D;
		    PC_D          <= PC_D;
		    pc4_D         <= pc4_D;    
		end
	end
endmodule

//---------------------------------------------------------------------------
//                                ID / EX
//---------------------------------------------------------------------------

//REGISTER FILE
module register_file(input clk , input [4:0] A1 , A2 , A3 ,
                     input WE3 , input [31:0] WD3 ,
                     output [31:0] RD1 , RD2);
  
  reg [31:0] register [31:0];  
  
  integer i;
   initial begin 
      for (i = 0; i < 32; i = i + 1) 
          register[i] = 32'b0;
   end
  
  assign RD1 = (A1 == 0) ? 32'b0 : register[A1];
  assign RD2 = (A2 == 0) ? 32'b0 : register[A2];
  
  always @ (posedge clk) begin
    if (WE3 == 1 && A3 !=0)
      register[A3] <= WD3;
  end
       
endmodule

// EXTEND
module extend(input [2:0]immsrc , input [31:0]instruction , output reg [31:0]immext);
  
  localparam R = 3'b000;
  localparam I = 3'b001;
  localparam S = 3'b010;
  localparam B = 3'b011;
  localparam J = 3'b100;
  
  always @(*)begin
    case(immsrc)
      R : immext = 32'b0;
      I : immext = {{20{instruction[31]}} , instruction[31:20]};
      S : immext = {{20{instruction[31]}} , instruction[31:25] , instruction[11:7]};
      B : immext = {{19{instruction[31]}} , instruction[31] , instruction [7] , instruction[30:25] , instruction[11:8] , 1'b0};
      J : immext = {{11{instruction[31]}} , instruction[31] , instruction[19:12] , instruction[20] , instruction[30:21] , 1'b0};
      default : immext = 32'bx;
    endcase
  end
endmodule

//PIPELINE REGISTER ID/EX
module ID_EX(input RegWrite , MemWrite , Jump , Branch , ALUsrc , JumpItr ,
             input [1:0] ResultSrc , StoreType , 
             input [2:0] LoadType, 
             input [3:0] ALUcontrol , 
             input [31:0] RD1 , RD2 , immext , PC_D , pc4_D , instruction_D,              input clk , reset , Flash_E ,
             output reg  RegWrite_E , MemWrite_E , Jump_E , Branch_E ,                                ALUsrc_E , JumpItr_E , 
             output reg [1:0] ResultSrc_E , StoreType_E , 
             output reg [2:0] LoadType_E , 
             output reg [3:0] ALUcontrol_E , 
             output reg [31:0]instruction_E ,                        
             output reg [31:0] RD1_E , RD2_E , immext_E , PC_E , pc4_E);
            
    always @ (posedge clk , posedge reset) begin
	    if(reset) begin
	        RegWrite_E   <= 0;
			MemWrite_E   <= 0;
			Jump_E       <= 0;
			Branch_E     <= 0;
			ALUsrc_E     <= 0;
			JumpItr_E    <= 0;
			ResultSrc_E  <= 2'b00;
			StoreType_E  <= 2'b00;
			LoadType_E   <= 3'b000;
			ALUcontrol_E <= 4'b0000;
			RD1_E        <= 32'b0;
			RD2_E        <= 32'b0;
			immext_E     <= 32'b0;
			PC_E         <= 32'b0;
			pc4_E        <= 32'b0;
			instruction_E <= 32'b0;
		end
		
		else if(Flash_E) begin
			RegWrite_E   <= 0;
			MemWrite_E   <= 0;
			Jump_E       <= 0;
			Branch_E     <= 0;
			ALUsrc_E     <= 0;
			JumpItr_E    <= 0;
			ResultSrc_E  <= 2'b00;
			StoreType_E  <= 2'b00;
			LoadType_E   <= 3'b000;
			ALUcontrol_E <= 4'b0000;
			RD1_E        <= 32'b0;
			RD2_E        <= 32'b0;
			immext_E     <= 32'b0;
			PC_E         <= 32'b0;
			pc4_E        <= 32'b0;
			instruction_E <= 32'b0;
		end

		else begin
		    RegWrite_E      <= RegWrite ;
 			MemWrite_E      <= MemWrite ;
			Jump_E          <= Jump ;
			Branch_E        <= Branch;
			ALUsrc_E        <= ALUsrc;
			JumpItr_E       <= JumpItr;
			ResultSrc_E     <= ResultSrc ;
			StoreType_E     <= StoreType ;
			LoadType_E      <= LoadType ;
			ALUcontrol_E    <= ALUcontrol ;
			instruction_E   <= instruction_D;
			RD1_E           <= RD1;
			RD2_E           <= RD2;
			immext_E        <= immext;
			PC_E            <= PC_D;
			pc4_E           <= pc4_D;
		end
	end
endmodule
					    
//---------------------------------------------------------------------------
//                                EX / MEM
//---------------------------------------------------------------------------

//BRANCH BOX
module branch_box(input [31:0] A1 , A2 , input [2:0]Branch , output reg BranchTaken);

    localparam BEQ  = 3'b000;             // rs1 == rs2 | equality
    localparam BNE  = 3'b001;             // rs1 != rs2 | equality
    localparam BLT  = 3'b100;             // rs1 < rs2  | signed   
    localparam BGE  = 3'b101;             // rs1 >= rs2 | signed       
    localparam BLTU = 3'b110;             // rs1 < rs2  | unsigned
    localparam BGEU = 3'b111;             // rs1 >= rs2 | unsigned

    always @ (*)begin
        case(Branch)
            BEQ  : BranchTaken = (A1 == A2);
            BNE  : BranchTaken = (A1 != A2);
            BLT  : BranchTaken = ($signed(A1) < $signed(A2));
            BGE  : BranchTaken = ($signed(A1) >= $signed(A2));
            BLTU : BranchTaken = (A1 < A2);
            BGEU : BranchTaken = (A1 >= A2);
            default : BranchTaken = 1'b0;
        endcase
    end
endmodule

//ALU
module alu(input [31:0] srcA , srcB , 
		   input [3:0]ALUcontrol , 
		   output reg [31:0]ALUresult);

localparam ADD  = 4'b0000;
localparam SUB  = 4'b0001;
localparam SLL  = 4'b0010;
localparam SLT  = 4'b0011;
localparam SLTU = 4'b0100;
localparam XOR  = 4'b0101;
localparam SRL  = 4'b0110;
localparam SRA  = 4'b0111;
localparam OR   = 4'b1000;
localparam AND  = 4'b1001;
  
	always @ (*)begin
	    case(ALUcontrol)
		    ADD  : ALUresult = srcA + srcB;
		    SUB  : ALUresult = srcA - srcB;
			SLL  : ALUresult = srcA << srcB[4:0];
		    SLT  : begin
				        if($signed(srcA) < $signed(srcB))
					        ALUresult = 32'b1;
				        else
					        ALUresult = 32'b0;
			      end
		    SLTU : begin
				        if(srcA < srcB)
					        ALUresult = 32'b1;
				        else
					        ALUresult = 32'b0;
				   end
		    XOR  : ALUresult = srcA ^ srcB;
		    SRL  : ALUresult = srcA >> srcB[4:0];
		    SRA  : ALUresult = $signed(srcA) >>> srcB[4:0];
		    OR   : ALUresult = srcA | srcB;
		    AND  : ALUresult = srcA & srcB;
		    default : ALUresult = 32'b0;
	    endcase
	end
endmodule

// PCTarget
module pc_target(input [31:0]immext , pc , output [31:0]pc_mux);
   
   assign pc_mux = pc + immext;
endmodule


// MUX1
module mux1(input [31:0] a , b , 
			input ALUsrc , 
			output [31:0]srcB);
			
  assign srcB = ALUsrc ? b : a;
  
endmodule

// MUX4
module mux4(input [31:0] a , b , 
			input JumpItr , 
			output [31:0]jump);
			
  assign jump = JumpItr ? b : a;
  
endmodule

//MUX5
module mux5(input [31:0] a , b , c ,
			input [1:0] forward_A ,
			output reg[31:0] srcA_E );
			
	always @(*) begin
		case (forward_A) 
			2'b00 : srcA_E = a;
			2'b01 : srcA_E = b;
			2'b10 : srcA_E = c;
			default : srcA_E = c;
		endcase
	end
endmodule

//MUX6
module mux6(input [31:0] a , b , c ,
			input [1:0] forward_B ,
			output reg[31:0] RD2_E );
			
	always @(*) begin
		case (forward_B) 
			2'b00 : RD2_E = a;
			2'b01 : RD2_E = b;
			2'b10 : RD2_E = c;
			default : RD2_E = a;
		endcase
	end
endmodule


//PCsrc Logic
module PCsrc_Logic(input Jump_E , Branch_E , BranchTaken , 
        output PCsrc);
    assign PCsrc = Jump_E | (Branch_E & BranchTaken);
endmodule

// PIPELINED REGISTER EX/MEM
module EX_MEM(input RegWrite_E , MemWrite_E , input [1:0] ResultSrc_E ,                           StoreType_E , input [2:0]LoadType_E , input [31:0]                           ALUresult , instruction_E , RD2_E , pc4_E , input clk ,                      reset ,
              output reg RegWrite_M , MemWrite_M , output reg [1:0]                                  ResultSrc_M ,StoreType_M , output reg [2:0]                                  LoadType_M , output reg [31:0] ALUresult_M ,                                 instruction_M , RD2_M , pc4_M);
	always @(posedge clk , posedge reset) begin
		if(reset) begin
			RegWrite_M <= 0; 
			MemWrite_M <= 0; 
			ResultSrc_M <= 2'b00; 
			StoreType_M <= 2'b00; 
			LoadType_M <= 3'b000; 
			ALUresult_M <= 32'b0; 
			instruction_M <= 32'b0; 
			RD2_M <= 32'b0; 
			pc4_M <= 32'b0; 
		end 
		else begin 
			RegWrite_M <= RegWrite_E; 
			MemWrite_M <= MemWrite_E; 
			ResultSrc_M <= ResultSrc_E; 
			StoreType_M <= StoreType_E; 
			LoadType_M <= LoadType_E; 
			ALUresult_M <= ALUresult; 
			instruction_M <= instruction_E; 
			RD2_M <= RD2_E; 
			pc4_M <= pc4_E; 
		end 
	end
endmodule	

//---------------------------------------------------------------------------
//                                MEM / WB
//---------------------------------------------------------------------------

// DATA MEMORY
module data_memory(input clk , input WE , input [31:0] A , WD , output [31:0]RD);
  reg [31:0] data_memory [0:1023];
  
  integer j;
   initial begin 
      for (j = 0; j < 1024; j = j + 1) 
          data_memory[j] = 32'b0;
   end
  
  always @ (posedge clk)begin
    if(WE == 1'b1)
      data_memory[A[11:2]] <= WD;
  end
  assign RD = data_memory[A[11:2]];
endmodule
    
// LOAD UNIT
module load_unit(input [31:0] ReadData , input [2:0] LoadType , output reg [31:0] LoadData);

    localparam LB  = 3'b000;
    localparam LH  = 3'b001;
    localparam LW  = 3'b010;
    localparam LBU = 3'b100;
    localparam LHU = 3'b101;

    always @(*) begin
        case (LoadType)
            LB  : LoadData = {{24{ReadData[7]}}, ReadData[7:0]};
            LH  : LoadData = {{16{ReadData[15]}}, ReadData[15:0]};
            LW  : LoadData = ReadData;
            LBU : LoadData = {24'b0, ReadData[7:0]};
            LHU : LoadData = {16'b0, ReadData[15:0]};
            default : LoadData = 32'b0;
        endcase
    end
  
endmodule

// STORE UNIT
module store_unit(input [31:0]RD2 , input [1:0]StoreType , output reg[31:0]StoreData);

    localparam SB = 2'b00;
    localparam SH = 2'b01;
    localparam SW = 2'b10;

    always @ (*)begin
        case(StoreType)
            SB : StoreData = {{24{1'b0}},RD2[7:0]};
            SH : StoreData = {{16{1'b0}},RD2[15:0]};
            SW : StoreData = RD2;
            default : StoreData = 32'b0;
        endcase
    end
endmodule

//PIPELINED REGISTER MEM / WB
module MEM_WB(input RegWrite_M , input [1:0]ResultSrc_M , input [31:0]                           ALUresult_M , LoadData , instruction_M , pc4_M ,
		            input clk , reset ,
              output reg RegWrite_W , output reg [1:0] ResultSrc_W , output                           reg [31:0] ALUresult_W , LoadData_W , instruction_W                          , pc4_W);
    always @ (posedge clk , posedge reset) begin
	    if(reset) begin
		    RegWrite_W <= 0; 
		    ResultSrc_W <= 2'b00; 
		    ALUresult_W <= 32'b0; 
		    LoadData_W <= 32'b0; 
		    instruction_W <= 32'b0; 
		    pc4_W <= 32'b0;
		end
		else begin
			RegWrite_W <= RegWrite_M; 
			ResultSrc_W <= ResultSrc_M; 
			ALUresult_W <= ALUresult_M; 
			LoadData_W <= LoadData; 
			instruction_W <= instruction_M; 
			pc4_W <= pc4_M;
		end
	end
endmodule

//---------------------------------------------------------------------------
//                                RESULT
//---------------------------------------------------------------------------

// MUX2
module mux2(input [31:0] a , b , c , input [1:0]ResultSrc , output reg[31:0]Result);
  always @ (*) begin
     case(ResultSrc)
        2'b00 : Result = a ;           // ALUresult
        2'b01 : Result = b ;           // LoadData
        2'b10 : Result = c ;           // pc4
        default : Result = 32'b0;
     endcase
  end
endmodule

//---------------------------------------------------------------------------
//                         CONTROL UNIT (ID / EX)
//---------------------------------------------------------------------------

//CONTROL UNIT
module control_unit(input [6:0] op , 
					input [2:0] funct3 , 
					input [6:0] funct7 ,   
                    output reg MemWrite , ALUsrc , RegWrite , JumpItr ,                                     Branch , Jump , 
				    output reg [3:0] ALUcontrol ,                                                output reg [2:0] ImmSrc , 
				    output reg [2:0] LoadType , 
				    output reg [1:0] StoreType , ResultSrc);
  
  always @ (*)begin
  
  //DEFAULT
       RegWrite   = 0;
       ALUsrc     = 0;
       MemWrite   = 0;
       ResultSrc  = 0;
       ImmSrc     = 0;
       ALUcontrol = 0;
       LoadType   = 0;
       StoreType  = 0;
       JumpItr    = 0;
       Jump       = 0;
       Branch     = 0;
    //
    // -------------------------- R TYPE ------------------------------
    //
    if(op == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000000)begin       //ADD
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b0000;
    end
      
    if(op == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0100000)begin       //SUB
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE;
       ALUcontrol = 4'b0001;
    end
    if(op == 7'b0110011 && funct3 == 3'b001 && funct7 == 7'b0000000)begin       //SLL
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE;
       ALUcontrol = 4'b0010;
    end
    if(op == 7'b0110011 && funct3 == 3'b010 && funct7 == 7'b0000000)begin       //SLT
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b0011;
    end
    if(op == 7'b0110011 && funct3 == 3'b011 && funct7 == 7'b0000000)begin       //SLTU
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b0100;
    end
    if(op == 7'b0110011 && funct3 == 3'b100 && funct7 == 7'b0000000)begin       //XOR
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b0101;
    end
    if(op == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0000000)begin       //SRL
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b0110;
    end
    if(op == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0100000)begin       //SRA
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b0111;
    end
    if(op == 7'b0110011 && funct3 == 3'b110 && funct7 == 7'b0000000)begin       //OR
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b1000;
    end
    if(op == 7'b0110011 && funct3 == 3'b111 && funct7 == 7'b0000000)begin       //AND
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b000;            //R TYPE
       ALUcontrol = 4'b1001;
    end
    //
    //---------------------------- I TYPE (ALU) ----------------------------
    //
      if(op == 7'b0010011 && funct3 == 3'b000)begin      //ADDI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
    end    
    if(op == 7'b0010011 && funct3 == 3'b010)begin      //SLTI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0011;
    end  
    if(op == 7'b0010011 && funct3 == 3'b011)begin      //SLTIU
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0100;
    end  
    if(op == 7'b0010011 && funct3 == 3'b100)begin      //XORI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0101;
    end  
    if(op == 7'b0010011 && funct3 == 3'b110)begin      //ORI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b1000;
    end  
    if(op == 7'b0010011 && funct3 == 3'b111)begin      //ANDI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b1001;
    end  
    if(op == 7'b0010011 && funct3 == 3'b001 && funct7 == 7'b0000000)begin       //SLLI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0010;
    end
    if(op == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0000000)begin       //SRLI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0110;
    end
    if(op == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0100000)begin       //SRAI
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b00;
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0111;
    end
    //
    //----------------------------I TYPE (LOAD)-----------------------------
    //
    if(op == 7'b0000011 && funct3 == 3'b000)begin      //LB
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b01;
       LoadType  = 3'b000;           //LB
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
    end 
    if(op == 7'b0000011 && funct3 == 3'b001)begin      //LH
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b01;
       LoadType  = 3'b001;           //LH
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
    end 
    if(op == 7'b0000011 && funct3 == 3'b010)begin      //LW
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b01;
       LoadType  = 3'b010;           //LW
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
    end 
    if(op == 7'b0000011 && funct3 == 3'b100)begin      //LBU
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b01;
       LoadType  = 3'b100;           //LBU
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
    end 
    if(op == 7'b0000011 && funct3 == 3'b101)begin      //LHU
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 2'b01;
       LoadType  = 3'b101;           //LHU
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
    end  
  //
  //----------------------------I TYPE (JUMP)-----------------------------
  //
  if(op == 7'b1100111 && funct3 == 3'b000)begin      //JALR
       RegWrite   = 1;
       ALUsrc     = 1;
       MemWrite   = 0;
       ResultSrc  = 2'b10;            // pc4 
       ImmSrc     = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
       JumpItr    = 1;
       Jump       = 1;
    end  
  //
  //-------------------------------S TYPE-----------------------------------
  //
  if(op == 7'b0100011 && funct3 == 3'b000)begin      //SB
       RegWrite  = 0;
       ALUsrc    = 1;
       MemWrite  = 1;
       ResultSrc = 0;
       ImmSrc    = 3'b010;           //S TYPE
       StoreType = 2'b00;            //SB  
       ALUcontrol = 4'b0000;
    end 
    if(op == 7'b0100011 && funct3 == 3'b001)begin      //SH
       RegWrite  = 0;
       ALUsrc    = 1;
       MemWrite  = 1;
       ResultSrc = 0;
       ImmSrc    = 3'b010;           //S TYPE
       StoreType = 2'b01;            //SH   
       ALUcontrol = 4'b0000;
    end 
  if(op == 7'b0100011 && funct3 == 3'b010)begin      //SW
       RegWrite  = 0;
       ALUsrc    = 1;
       MemWrite  = 1;
       ResultSrc = 0;
       ImmSrc    = 3'b010;           //S TYPE
       StoreType = 2'b10;            //SW   
       ALUcontrol = 4'b0000;
    end 
    //
    //------------------------------B TYPE---------------------------
    //
    if(op == 7'b1100011 && funct3 == 3'b000 )begin      //BEQ
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       Branch     = 1;
    end   
    if(op == 7'b1100011 && funct3 == 3'b001)begin         //BNE
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       Branch     = 1;

    end
    if(op == 7'b1100011 && funct3 == 3'b100)begin          //BLT
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       Branch     = 1;
    end
    if(op == 7'b1100011 && funct3 == 3'b101)begin     //BGE
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       Branch     = 1;
    end
    if(op == 7'b1100011 && funct3 == 3'b110)begin   //BLTU
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       Branch     = 1;
    end
    if(op == 7'b1100011 && funct3 == 3'b111)begin    //BGEU
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       Branch     = 1;
    end
    //
    //------------------------------J TYPE---------------------------
    //
    if(op == 7'b1101111)begin                 //JAL
       RegWrite   = 1;
       MemWrite   = 0;
       ResultSrc  = 2'b10;
       ImmSrc     = 3'b100;
       JumpItr    = 0;
       Jump       = 1;
    end
    
  end
endmodule

//---------------------------------------------------------------------------
//                                HAZARD UNIT
//---------------------------------------------------------------------------

// HAZARD UNIT
module hazard_unit (input [4:0] Rs1D , Rs2D , Rs1E , Rs2E , RdE ,RdM , RdW ,
                    input PCsrc , RegWrite_M , RegWrite_W , 
                    input [1:0] ResultSrc_E ,
                    output reg [1:0] forward_A , forward_B ,
                    output reg Flash_E , Flash_D , Stall_D , Stall_F);

	always @(*) begin

    forward_A = 2'b00;
    forward_B = 2'b00;
    Flash_E = 1'b0;
    Flash_D = 1'b0;
    Stall_D = 1'b0;
    Stall_F = 1'b0;
	
//----------------------------- FORWARDING ----------------------------------
		begin                                                 // Rs1E
			if((Rs1E == RdM) && RegWrite_M && (Rs1E != 0))
				forward_A = 2'b01;        //  c
			else if((Rs1E == RdW) && RegWrite_W && (Rs1E != 0))
				forward_A = 2'b00;        //  a
			else
				forward_A = 2'b10;        //  b
		end

		begin                                                 // Rs2E
			if((Rs2E == RdM) && RegWrite_M && (Rs2E != 0))
				forward_B = 2'b01;        //  b
			else if((Rs2E == RdW) && RegWrite_W && (Rs2E != 0))
				forward_B = 2'b10;        //  c
			else
				forward_B = 2'b00;        //  a
		end

//---------------------------- DATA HAZARD (lw) -----------------------------
		begin
			if((RdE == Rs1D) && (ResultSrc_E ==2'b01) && (RdE !=0))
				begin
					Stall_F = 1'b1;	
					Stall_D = 1'b1;
					Flash_E = 1'b1;
				end
				
			if((RdE == Rs2D) && ResultSrc_E && (RdE !=0))
				begin
					Stall_F = 1'b1;	
					Stall_D = 1'b1;
					Flash_E = 1'b1;
				end
		end

//--------------------------- DATA HAZARD (branch) --------------------------
		begin
			if(PCsrc == 1'b1) 
				begin
					Flash_D = 1'b1;
					Flash_E = 1'b1;
				end
		end
	
	end	
endmodule

//---------------------------------------------------------------------------
//                                 DATAPATH
//---------------------------------------------------------------------------

module datapath(input clk , reset); 

// ------------------------------- IF -----------------------------------
wire [31:0] PC , pc4 , pc_next , instruction , jump ;
wire PCsrc ;

// ---------------------------------- ID ------------------------------------
wire [31:0] instruction_D , PC_D , pc4_D , instruction_W , Result;
wire [31:0] RD1 , RD2 , immext ;
wire RegWrite , MemWrite , ALUsrc , JumpItr , Branch , Jump ;
wire [1:0]  ResultSrc , StoreType ;
wire [2:0]  LoadType , immsrc ;
wire [3:0]  ALUcontrol ;

// ---------------------------------- EX ------------------------------------
wire [31:0] srcA_E , RD2_E , immext_E , PC_E , pc4_E , instruction_E , A , B;
wire RegWrite_E , MemWrite_E , ALUsrc_E , JumpItr_E , Branch_E , Jump_E ;
wire [1:0]  ResultSrc_E , StoreType_E ;
wire [2:0]  LoadType_E ;
wire [3:0]  ALUcontrol_E ;
wire [31:0] srcB , ALUresult , pc_mux ;
wire BranchTaken ; 

// ---------------------------------- MEM -----------------------------------
wire [31:0] ALUresult_M , RD2_M , pc4_M , instruction_M ;
wire RegWrite_M , MemWrite_M ;
wire [1:0]  ResultSrc_M , StoreType_M ;
wire [2:0]  LoadType_M ;
wire [31:0] StoreData , ReadData , LoadData ;

// ---------------------------------- WB ------------------------------------
wire [31:0] ALUresult_W , LoadData_W , pc4_W ;
wire RegWrite_W ;
wire [1:0]  ResultSrc_W ;

//------------------------------ HAZARD UNIT --------------------------------
wire [1:0] forward_A , forward_B ;
wire Flash_E , Flash_D , Stall_D , Stall_F ;
    
    
//------------------------REGISTER FILE----------------------

  register_file RF(
    .clk(clk) ,
    .A1(instruction_D[19:15]) ,
    .A2(instruction_D[24:20]) ,
    .A3(instruction_W[11:7]) ,
    .WE3(RegWrite_W) , 
    .WD3(Result) ,
    .RD1(RD1) , 
    .RD2(RD2) 
  );
  
//-----------------------LOAD UNIT------------------------
  
  load_unit LU(
    .ReadData(ReadData) , 
    .LoadData(LoadData) , 
    .LoadType(LoadType_M) 
  );
  
  //-----------------------STORE UNIT------------------------
  
  store_unit SU(
    .RD2(RD2_M) , 
    .StoreData(StoreData) , 
    .StoreType(StoreType_M) 
  );
  
//-----------------------------EXTEND-----------------------------

extend E(
   .instruction(instruction_D) ,
   .immsrc(immsrc) , 
   .immext(immext)
);

//-----------------------------ALU---------------------------------

alu A(
   .srcA(srcA_E) ,
   .srcB(srcB) ,
   .ALUresult(ALUresult),
   .ALUcontrol(ALUcontrol_E) 
);

//--------------------------DATA MEMORY-----------------------------

data_memory DM(
   .clk(clk) ,
   .WE(MemWrite_M) , 
   .A(ALUresult_M) , 
   .WD(StoreData) ,
   .RD(ReadData)
   );
   
//---------------------------------PC---------------------------------
pc pc_block(
   .clk(clk) , 
   .pc_current(PC) ,
   .pc_next(pc_next) ,
   .Stall_F(Stall_F)
);

//----------------------------PC + 4 ADDER-----------------------------

pc_4adder PC4(
   .pc(PC) ,
   .pc4(pc4)
);

//---------------------------------PC TARGET---------------------------------
pc_target PC_4(
   .immext(immext_E) , 
   .pc(PC_E) ,
   .pc_mux(pc_mux)
);

//-------------------------------BRANCH BOX----------------------------------

branch_box BB(
   .A1(srcA_E) ,
   .A2(RD2_E) ,
   .Branch(instruction_E[14:12]) ,
   .BranchTaken(BranchTaken)
);

//-------------------------INSTRUCTION MEMORY---------------------------

instruction_memory IM(
   .A(PC) ,
   .RD(instruction)
);

//-------------------------------MUX 1---------------------------------

mux1 M1(
.a(RD2_E) ,
.b(immext_E) ,
.ALUsrc(ALUsrc_E) ,
.srcB(srcB)
);

//-------------------------------MUX 2---------------------------------

mux2 M2(
.a(ALUresult_W) ,
.b(LoadData_W) ,
.c(pc4_W),
.ResultSrc(ResultSrc_W) ,
.Result(Result)
);

//-------------------------------MUX 3---------------------------------

mux3 M3(
.a(pc4) ,
.b(jump) ,
.pc_next(pc_next) ,
.PCsrc(PCsrc)
);

//-------------------------------MUX 4---------------------------------

mux4 M4(
.a(pc_mux) ,
.b(ALUresult & ~1) ,
.jump(jump) ,
.JumpItr(JumpItr_E)
);

//-------------------------------MUX 5---------------------------------

mux5 M5(
.a(Result) ,
.b(ALUresult_M) ,
.c(A),
.forward_A(forward_A) ,
.srcA_E(srcA_E)
);

//-------------------------------MUX 6---------------------------------

mux6 M6(
.a(B) ,
.b(ALUresult_M) ,
.c(Result),
.forward_B(forward_B) ,
.RD2_E(RD2_E)
);

//-------------------------------PCsrc Logic---------------------------------

PCsrc_Logic PCL(
.PCsrc(PCsrc) ,
.Jump_E(Jump_E) ,
.Branch_E(Branch_E) ,
.BranchTaken(BranchTaken)
);

//-----------------------------CONTROL UNIT-------------------------------

control_unit CU(
   .op(instruction_D[6:0]) ,
   .funct3(instruction_D[14:12]) ,
   .funct7(instruction_D[31:25]) ,
   .ResultSrc(ResultSrc) ,
   .LoadType(LoadType) ,
   .MemWrite(MemWrite) ,
   .ALUcontrol(ALUcontrol) ,
   .ALUsrc(ALUsrc) ,
   .ImmSrc(immsrc) ,
   .RegWrite(RegWrite) ,
   .StoreType(StoreType) ,
   .Jump(Jump) ,
   .Branch(Branch) ,
   .JumpItr(JumpItr)
);

//---------------------------------IF / ID---------------------------------- 

IF_ID register1(
   .clk(clk) ,
   .reset(reset) ,
   .instruction(instruction) ,
   .PC(PC) ,
   .pc4(pc4) ,
   .instruction_D(instruction_D) ,
   .PC_D(PC_D) ,
   .pc4_D(pc4_D) ,
   .Flash_D(Flash_D) ,
   .Stall_D(Stall_D)
);

//---------------------------------ID / EX---------------------------------- 

ID_EX register2(
   .clk(clk) ,
   .reset(reset) ,
   .RegWrite(RegWrite) ,
   .ResultSrc(ResultSrc) ,
   .LoadType(LoadType) ,
   .MemWrite(MemWrite) ,
   .StoreType(StoreType) ,
   .Jump(Jump) ,
   .Branch(Branch) ,
   .ALUcontrol(ALUcontrol) ,
   .ALUsrc(ALUsrc) ,
   .JumpItr(JumpItr) ,
   .RD1(RD1) ,
   .RD2(RD2) ,
   .immext(immext) ,
   .PC_D(PC_D) ,
   .pc4_D(pc4_D) ,
   .instruction_D(instruction_D) ,
   .RegWrite_E(RegWrite_E) ,
   .ResultSrc_E(ResultSrc_E) ,
   .LoadType_E(LoadType_E) ,
   .MemWrite_E(MemWrite_E) ,
   .StoreType_E(StoreType_E) ,
   .Jump_E(Jump_E) ,
   .Branch_E(Branch_E) ,
   .ALUcontrol_E(ALUcontrol_E) ,
   .ALUsrc_E(ALUsrc_E) ,
   .JumpItr_E(JumpItr_E) ,
   .RD1_E(A) ,
   .RD2_E(B) ,
   .immext_E(immext_E) ,
   .PC_E(PC_E) ,
   .pc4_E(pc4_E) ,
   .instruction_E(instruction_E) ,
   .Flash_E(Flash_E)
);

//--------------------------------EX / MEM---------------------------------- 

EX_MEM register3(
	.clk(clk) ,
	.reset(reset) , 
	.RegWrite_E(RegWrite_E) ,
	.ResultSrc_E(ResultSrc_E) ,
	.LoadType_E(LoadType_E) ,
	.MemWrite_E(MemWrite_E) ,
	.StoreType_E(StoreType_E) , 
	.ALUresult(ALUresult) ,
	.RD2_E(RD2_E) ,
	.instruction_E(instruction_E) ,
	.pc4_E(pc4_E) ,
	.RegWrite_M(RegWrite_M) ,
	.ResultSrc_M(ResultSrc_M) ,
	.LoadType_M(LoadType_M) ,
	.MemWrite_M(MemWrite_M) ,
	.StoreType_M(StoreType_M) , 
	.ALUresult_M(ALUresult_M) ,
	.RD2_M(RD2_M) ,
	.instruction_M(instruction_M) ,
	.pc4_M(pc4_M) 
);

//--------------------------------MEM / WB----------------------------------

MEM_WB register4(
	.clk(clk) ,
	.reset(reset) ,
	.RegWrite_M(RegWrite_M) ,
	.ResultSrc_M(ResultSrc_M) ,
	.ALUresult_M(ALUresult_M) ,
	.LoadData(LoadData) ,
	.pc4_M(pc4_M) ,
	.instruction_M(instruction_M) ,
	.RegWrite_W(RegWrite_W) ,
	.ResultSrc_W(ResultSrc_W) ,
	.ALUresult_W(ALUresult_W) ,
	.LoadData_W(LoadData_W) ,
	.pc4_W(pc4_W) ,
	.instruction_W(instruction_W)
); 

//------------------------------ HAZARD UNIT --------------------------------

hazard_unit Hazard(
    .Rs1D(instruction_D[19:15]),
    .Rs2D(instruction_D[24:20]),
    .Rs1E(instruction_E[19:15]),
    .Rs2E(instruction_E[24:20]),
    .RdE(instruction_E[11:7]),
    .RdM(instruction_M[11:7]),
    .RdW(instruction_W[11:7]),
    .PCsrc(PCsrc),
    .RegWrite_M(RegWrite_M),
    .RegWrite_W(RegWrite_W),
    .ResultSrc_E(ResultSrc_E),     
    .forward_A(forward_A),         
    .forward_B(forward_B),         
    .Flash_E(Flash_E),
    .Flash_D(Flash_D),
    .Stall_D(Stall_D),
    .Stall_F(Stall_F)
);

endmodule

