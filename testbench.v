module tb_pc;

	reg clk , Stall_F ;
	reg [31:0] pc_next , expectation ; 
	wire [31:0] pc_current ;
	integer i , error ;
	
	pc DUT(
		.clk(clk) , 
		.Stall_F(Stall_F) ,
		.pc_next(pc_next) ,
		.pc_current(pc_current)
	);
	
	initial clk = 0;
	always #5 clk = ~clk;
	
	initial begin
		pc_next = 32'b0 ;
		Stall_F = 0 ;
		error = 0 ;
		expectation = 0 ;
		
		for(i = 0 ; i < 10000 ; i = i + 1 ) begin
			@(negedge clk);
			Stall_F = 0 ;
			pc_next = $urandom ;
			expectation = pc_next ;
			
			@(posedge clk) ;
			#1 ;
			if(expectation != pc_current) begin
				error = error + 1 ;
			    if(error <= 1)
					$display("FAIL: expected %0d got %0d", expectation , pc_current);
            end
        end
        for(i = 0 ; i < 10000 ; i = i + 1 ) begin
			@(negedge clk);       
			Stall_F = 1 ;
			pc_next = $urandom ;
			expectation = expectation ;
			
			@(posedge clk) ;
			#1 ;
			if(expectation != pc_current) begin
				error = error + 1 ;
			    if(error <= 1)
					$display("FAIL: expected %0d got %0d", expectation , pc_current);
            end
        end
        
        if(error == 0)
	        $display("PASS");
	    else
		    $display("FAIL : error = %d" , error);
	$finish;
	end
endmodule	
	
