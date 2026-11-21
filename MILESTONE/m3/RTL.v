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
      
//ALU
module alu(input [31:0] srcA , srcB , input [3:0]ALUcontrol , output reg Zero , output reg [31:0]ALUresult);

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
    
    Zero = (ALUresult == 32'b0);
    
  end
endmodule

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
    
//PC
module pc(input [31:0] pc_next , input clk , output reg [31:0]pc_current );
  initial pc_current = 32'b0;
  always @(posedge clk)
    pc_current <= pc_next;
  
endmodule

//PC + 4 ADDER
module pc_4adder(input [31:0]pc , output [31:0]pc4);
  
  assign pc4 = pc + 32'd4;
  
endmodule

// PCTarget
module pc_target(input [31:0]immext , pc , output [31:0]pc_mux);
   
   assign pc_mux = pc + immext;
endmodule

//INSTRUCTION MEMORY
module instruction_memory(input [31:0]A , output [31:0]RD);
  
  reg [31:0] instruction_memory [0:1023];
  initial $readmemh("program.hex", instruction_memory);
  
  assign RD = instruction_memory [A[11:2]];       // to select which memory location we want.
  
endmodule

// MUX1
module mux1(input [31:0] a , b , input ALUsrc , output [31:0]srcB);
  assign srcB = ALUsrc ? b : a;
endmodule

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

// MUX3
module mux3(input [31:0] a , b , input PCsrc , output [31:0]pc_next);
  assign pc_next = PCsrc ? b : a;
endmodule

// MUX4
module mux4(input [31:0] a , b , input JumpItr , output [31:0]jump);
  assign jump = JumpItr ? b : a;
endmodule

//CONTROL UNIT
module control_unit(input [6:0]op , input [2:0]funct3 , input[6:0]funct7 , input Zero, input BranchTaken ,
                    output reg MemWrite , ALUsrc , RegWrite , JumpItr , PCsrc , output reg [3:0]ALUcontrol , output reg [2:0]ImmSrc , output reg [2:0]LoadType , output reg [1:0] StoreType , ResultSrc);
  
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
       PCsrc      = 0;
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
       ImmSrc    = 3'b001;            //I TYPE
       ALUcontrol = 4'b0000;
       JumpItr    = 1;
       PCsrc      = 1;
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
       PCsrc     = BranchTaken;
    end   
    if(op == 7'b1100011 && funct3 == 3'b001)begin         //BNE
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       PCsrc     = BranchTaken;

    end
    if(op == 7'b1100011 && funct3 == 3'b100)begin          //BLT
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       PCsrc     = BranchTaken;
    end
    if(op == 7'b1100011 && funct3 == 3'b101)begin     //BGE
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       PCsrc     = BranchTaken;
    end
    if(op == 7'b1100011 && funct3 == 3'b110)begin   //BLTU
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       PCsrc     = BranchTaken;
    end
    if(op == 7'b1100011 && funct3 == 3'b111)begin    //BGEU
       RegWrite  = 0;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 3'b011;           // B TYPE
       PCsrc     = BranchTaken;
    end
    //
    //------------------------------J TYPE---------------------------
    //
    if(op == 7'b1101111)begin
       RegWrite   = 1;
       MemWrite   = 0;
       ResultSrc  = 2'b10;
       ImmSrc     = 3'b100;
       JumpItr    = 0;
       PCsrc      = 1;
    end
    
  end
endmodule
  
module datapath(input clk); 
                 
    wire [31:0] RD2 ;                           
    wire [31:0] ReadData ;
    wire [31:0] LoadData ;                                        
    wire [31:0] instruction ;
    wire [31:0] immext , jump;                                            
    wire [31:0] srcA , srcB ;
    wire [31:0] ALUresult ;                         
    wire [31:0] PC ;
    wire [31:0] pc_next ; 
    wire [31:0] pc4 , pc_mux;                                                    wire [31:0] Result ;
    wire [31:0] StoreData ;
    wire BranchTaken ;                                 
    wire ZERO ;
    wire MemWrite , ALUsrc , RegWrite , PCsrc;
    wire [3:0] ALUcontrol ; 
    wire [2:0] Branch ;
    wire [1:0] StoreType , ResultSrc; 
    wire [2:0] LoadType , ImmSrc;   
    wire JumpItr;
    
    
//------------------------REGISTER FILE----------------------

  register_file RF(
    .clk(clk) ,
    .A1(instruction[19:15]) ,
    .A2(instruction[24:20]) ,
    .A3(instruction[11:7]) ,
    .WE3(RegWrite) , 
    .WD3(Result) ,
    .RD1(srcA) , 
    .RD2(RD2) 
  );
  
//-----------------------LOAD UNIT------------------------
  
  load_unit LU(
    .ReadData(ReadData) , 
    .LoadData(LoadData) , 
    .LoadType(LoadType) 
  );
  
  //-----------------------STORE UNIT------------------------
  
  store_unit SU(
    .RD2(RD2) , 
    .StoreData(StoreData) , 
    .StoreType(StoreType) 
  );
  
//-----------------------------EXTEND-----------------------------

extend E(
   .instruction(instruction) ,
   .immsrc(ImmSrc) , 
   .immext(immext)
);

//-----------------------------ALU---------------------------------

alu A(
   .srcA(srcA) ,
   .srcB(srcB) ,
   .ALUresult(ALUresult),
   .ALUcontrol(ALUcontrol) ,
   .Zero(ZERO)
);

//--------------------------DATA MEMORY-----------------------------

data_memory DM(
   .clk(clk) ,
   .WE(MemWrite) , 
   .A(ALUresult) , 
   .WD(StoreData) ,
   .RD(ReadData)
   );
   
//---------------------------------PC---------------------------------
pc pc_block(
   .clk(clk) , 
   .pc_current(PC) ,
   .pc_next(pc_next)
);

//----------------------------PC + 4 ADDER-----------------------------

pc_4adder PC4(
   .pc(PC) ,
   .pc4(pc4)
);

//---------------------------------PC TARGET---------------------------------
pc_target PC_4(
   .immext(immext) , 
   .pc(PC) ,
   .pc_mux(pc_mux)
);

//-------------------------------BRANCH BOX----------------------------------

branch_box BB(
   .A1(srcA) ,
   .A2(RD2) ,
   .Branch(instruction[14:12]) ,
   .BranchTaken(BranchTaken)
);


//-------------------------INSTRUCTION MEMORY---------------------------

instruction_memory IM(
   .A(PC) ,
   .RD(instruction)
);

//-------------------------------MUX 1---------------------------------

mux1 M1(
.a(RD2) ,
.b(immext) ,
.ALUsrc(ALUsrc) ,
.srcB(srcB)
);

//-------------------------------MUX 2---------------------------------

mux2 M2(
.a(ALUresult) ,
.b(LoadData) ,
.c(pc4),
.ResultSrc(ResultSrc) ,
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
.JumpItr(JumpItr)
);

//-----------------------------CONTROL UNIT-------------------------------

control_unit CU(
   .op(instruction[6:0]) ,
   .funct3(instruction[14:12]) ,
   .funct7(instruction[31:25]) ,
   .Zero(ZERO) ,
   .BranchTaken(BranchTaken) ,
   .ResultSrc(ResultSrc) ,
   .LoadType(LoadType) ,
   .MemWrite(MemWrite) ,
   .ALUcontrol(ALUcontrol) ,
   .ALUsrc(ALUsrc) ,
   .ImmSrc(ImmSrc) ,
   .RegWrite(RegWrite) ,
   .StoreType(StoreType) ,
   .PCsrc(PCsrc) ,
   .JumpItr(JumpItr)
   );

endmodule
