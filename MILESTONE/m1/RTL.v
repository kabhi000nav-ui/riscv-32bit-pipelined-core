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


module load_unit(input [31:0] ReadData , input [2:0] LoadType , output reg [31:0] LoadAddress);

    localparam LB  = 3'b000;
    localparam LH  = 3'b001;
    localparam LW  = 3'b010;
    localparam LBU = 3'b100;
    localparam LHU = 3'b101;

    always @(*) begin
        case (LoadType)
            LB  : LoadAddress = {{24{ReadData[7]}}, ReadData[7:0]};
            LH  : LoadAddress = {{16{ReadData[15]}}, ReadData[15:0]};
            LW  : LoadAddress = ReadData;
            LBU : LoadAddress = {24'b0, ReadData[7:0]};
            LHU : LoadAddress = {16'b0, ReadData[15:0]};
            default : LoadAddress = 32'b0;
        endcase
    end

endmodule


module store_unit(input [31:0]RD2 , input [1:0]StoreType , output reg[31:0]StoreData);

    localparam SB = 2'b00;
    localparam SH = 2'b01;
    localparam SW = 2'b10;

    always @ (*)begin
        case(StoreType)
            SB : StoreData = {{24{1'b0}},RD2[7:0]};
            SH : StoreData = {{16{1'b0}},RD2[15:0]};
            SW : StoreData = RD2;
            default : StoreData = RD2;
        endcase
    end
endmodule


module extend(input [1:0]immsrc , input [31:0]instruction , output reg [31:0]immext);

  localparam R = 2'b00;
  localparam I = 2'b01;
  localparam S = 2'b10;

  always @(*)begin
    case(immsrc)
      R : immext = 32'b0;
      I : immext = {{20{instruction[31]}} , instruction[31:20]};
      S : immext = {{20{instruction[31]}} , instruction[31:25] , instruction[11:7]};
      default : immext = 32'bx;
    endcase
  end
endmodule


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
   default : ALUresult = 32'bx;
    endcase

    Zero = (ALUresult == 32'b0);

  end
endmodule


module data_memory(input clk , input WE , input [31:0] A , WD , output [31:0]RD);
  reg [31:0] data_memory [0:1023];
  integer i;

  initial begin
    for (i = 0; i < 1024; i = i + 1)
      data_memory[i] = 32'b0;
  end

  always @ (posedge clk)begin
    if(WE == 1'b1)
      data_memory[A[11:2]] <= WD;
  end
  assign RD = data_memory[A[11:2]];
endmodule


module pc(input [31:0] pc_next , input clk , output reg [31:0]pc_current );

  initial pc_current = 32'b0;

  always @(posedge clk)
    pc_current <= pc_next;

endmodule


module pc_4adder(input [31:0]pc , output [31:0]pc_next);

  assign pc_next = pc + 32'd4;

endmodule


module instruction_memory(input [31:0]A , output [31:0]RD);

  reg [31:0] instruction_memory [0:1023];

  initial $readmemh("program.hex", instruction_memory);

  assign RD = instruction_memory [A[11:2]];

endmodule


module mux1(input [31:0] a , b , input ALUsrc , output [31:0]srcB);
  assign srcB = ALUsrc ? b : a;
endmodule


module mux2(input [31:0] a , b , input ResultSrc , output [31:0]Result);
  assign Result = ResultSrc ? b : a;
endmodule


module control_unit(input [6:0]op , input [2:0]funct3 , input[6:0]funct7 , input Zero,
                    output reg ResultSrc , MemWrite , ALUsrc , RegWrite , output reg [3:0]ALUcontrol , output reg [1:0]ImmSrc , output reg [2:0]LoadType , output reg [1:0]StoreType);

  always @ (*)begin

    RegWrite   = 0;
    ALUsrc     = 0;
    MemWrite   = 0;
    ResultSrc  = 0;
    ImmSrc     = 2'b00;
    ALUcontrol = 4'b0000;
    LoadType   = 3'b000;
    StoreType  = 2'b00;

    if(op == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0000;
    end

    if(op == 7'b0110011 && funct3 == 3'b000 && funct7 == 7'b0100000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0001;
    end
    if(op == 7'b0110011 && funct3 == 3'b001 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0010;
    end
    if(op == 7'b0110011 && funct3 == 3'b010 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0011;
    end
    if(op == 7'b0110011 && funct3 == 3'b011 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0100;
    end
    if(op == 7'b0110011 && funct3 == 3'b100 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0101;
    end
    if(op == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0110;
    end
    if(op == 7'b0110011 && funct3 == 3'b101 && funct7 == 7'b0100000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b0111;
    end
    if(op == 7'b0110011 && funct3 == 3'b110 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b1000;
    end
    if(op == 7'b0110011 && funct3 == 3'b111 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 0;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 0;
       ALUcontrol = 4'b1001;
    end

    if(op == 7'b0010011 && funct3 == 3'b000)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0000;
    end
    if(op == 7'b0010011 && funct3 == 3'b010)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0011;
    end
    if(op == 7'b0010011 && funct3 == 3'b011)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0100;
    end
    if(op == 7'b0010011 && funct3 == 3'b100)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0101;
    end
    if(op == 7'b0010011 && funct3 == 3'b110)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b1000;
    end
    if(op == 7'b0010011 && funct3 == 3'b111)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b1001;
    end
    if(op == 7'b0010011 && funct3 == 3'b001 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0010;
    end
    if(op == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0000000)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0110;
    end
    if(op == 7'b0010011 && funct3 == 3'b101 && funct7 == 7'b0100000)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 0;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0111;
    end

    if(op == 7'b0000011 && funct3 == 3'b000)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 1;
       LoadType  = 3'b000;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0000;
    end
    if(op == 7'b0000011 && funct3 == 3'b001)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 1;
       LoadType  = 3'b001;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0000;
    end
    if(op == 7'b0000011 && funct3 == 3'b010)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 1;
       LoadType  = 3'b010;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0000;
    end
    if(op == 7'b0000011 && funct3 == 3'b100)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 1;
       LoadType  = 3'b100;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0000;
    end
    if(op == 7'b0000011 && funct3 == 3'b101)begin
       RegWrite  = 1;
       ALUsrc    = 1;
       MemWrite  = 0;
       ResultSrc = 1;
       LoadType  = 3'b101;
       ImmSrc    = 2'b01;
       ALUcontrol = 4'b0000;
    end

    if(op == 7'b0100011 && funct3 == 3'b000)begin
       RegWrite  = 0;
       ALUsrc    = 1;
       MemWrite  = 1;
       ResultSrc = 0;
       ImmSrc    = 2'b10;
       StoreType = 2'b00;
       ALUcontrol = 4'b0000;
    end
    if(op == 7'b0100011 && funct3 == 3'b001)begin
       RegWrite  = 0;
       ALUsrc    = 1;
       MemWrite  = 1;
       ResultSrc = 0;
       ImmSrc    = 2'b10;
       StoreType = 2'b01;
       ALUcontrol = 4'b0000;
    end
    if(op == 7'b0100011 && funct3 == 3'b010)begin
       RegWrite  = 0;
       ALUsrc    = 1;
       MemWrite  = 1;
       ResultSrc = 0;
       ImmSrc    = 2'b10;
       StoreType = 2'b10;
       ALUcontrol = 4'b0000;
    end

  end
endmodule


module datapath(input clk);

    wire [31:0] RD2 ;
    wire [31:0] ReadData ; wire [31:0] LoadAddress ;
    wire [31:0] StoreData ;
    wire [31:0]instruction ; wire [31:0]immext ;
    wire [31:0] srcA , srcB ; wire [31:0]ALUresult ;
    wire [31:0]PC ; wire [31:0]pc_next ;
    wire [31:0]Result ;

    wire ZERO; wire ResultSrc , MemWrite , ALUsrc , RegWrite ; wire [3:0]ALUcontrol ; wire [1:0]ImmSrc ; wire [2:0]LoadType ; wire [1:0]StoreType ;

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

  load_unit LU(
    .ReadData(ReadData) ,
    .LoadAddress(LoadAddress) ,
    .LoadType(LoadType)
  );

  store_unit SU(
    .RD2(RD2) ,
    .StoreData(StoreData) ,
    .StoreType(StoreType)
  );

  extend E(
    .instruction(instruction) ,
    .immsrc(ImmSrc) ,
    .immext(immext)
  );

  alu A(
    .srcA(srcA) ,
    .srcB(srcB) ,
    .ALUresult(ALUresult),
    .ALUcontrol(ALUcontrol) ,
    .Zero(ZERO)
  );

  data_memory DM(
    .clk(clk) ,
    .WE(MemWrite) ,
    .A(ALUresult) ,
    .WD(StoreData) ,
    .RD(ReadData)
  );

  pc PC_reg(
    .clk(clk) ,
    .pc_current(PC) ,
    .pc_next(pc_next)
  );

  pc_4adder PC4(
    .pc(PC) ,
    .pc_next(pc_next)
  );

  instruction_memory IM(
    .A(PC) ,
    .RD(instruction)
  );

  mux1 M1(
    .a(RD2) ,
    .b(immext) ,
    .ALUsrc(ALUsrc) ,
    .srcB(srcB)
  );

  mux2 M2(
    .a(ALUresult) ,
    .b(LoadAddress) ,
    .ResultSrc(ResultSrc) ,
    .Result(Result)
  );

  control_unit CU(
    .op(instruction[6:0]) ,
    .funct3(instruction[14:12]) ,
    .funct7(instruction[31:25]) ,
    .Zero(ZERO) ,
    .ResultSrc(ResultSrc) ,
    .LoadType(LoadType) ,
    .StoreType(StoreType) ,
    .MemWrite(MemWrite) ,
    .ALUcontrol(ALUcontrol) ,
    .ALUsrc(ALUsrc) ,
    .ImmSrc(ImmSrc) ,
    .RegWrite(RegWrite)
  );

endmodule