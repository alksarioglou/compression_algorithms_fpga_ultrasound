`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.04.2021 23:37:08
// Design Name: 
// Module Name: mvbf_signal_processing
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_compression_signal_processing(
    );
    
    logic         clk_gen;
    logic         reset_n_gen;
    logic [25:0]   data_gen; //change it to [319:0]
    logic         data_valid_gen;
    logic [25:0]   I_data_chk;// change it to [319:0]
    logic [25:0]   Q_data_chk;
    logic         data_valid_chk;
    logic [5:0]   counter;
    logic         simulation_running;
	
	compression_signal_processing dut  (
	   .clk_i(clk_gen),
	   .reset_ni(reset_n_gen),
	   .data_i(data_gen),
	   .data_valid_i(data_valid_gen),
	   .I_data_o(I_data_chk),
       .Q_data_o(Q_data_chk),
	   .data_valid_o(data_valid_chk)
	);
	
	//reset everything after 25 time units
	initial begin
        clk_gen = 0;
        reset_n_gen = 0;
        data_gen = '0;
        data_valid_gen = 0;
        counter = '0;
        simulation_running = 1;
	    #5 reset_n_gen = 1;
	    
	    //finish simulation after...
	    //#200 simulation_running = 0;
	end
	
	//generate clk signal
	always begin
	   #5 clk_gen = ~clk_gen;
	end
	
	//stimulus
	integer stimulus_file,results_file,results_file_2;
	
	//read input stimulus from file
    initial begin
        stimulus_file= $fopen("testbench_input_acq_1.txt","r");
        if (stimulus_file==0) begin
            $display("Could not open testbench_input.txt");
            $stop;     
        end
        while (simulation_running) begin
            @(posedge clk_gen);
            if (! $feof(stimulus_file)) begin
                if (counter == 6'd21) begin
                    $fscanf(stimulus_file,"%h\n",data_gen);
                    data_valid_gen = 1;
                    counter = '0;
                end else begin
                    counter = counter + 1;
                end
            end
            else begin
                data_gen = '0;
                data_valid_gen = 0;
                simulation_running = 0;
            end
        end
        //simulation done
        $fclose(stimulus_file);
        #100; //give some time to close also results file
        $finish;
    end
    
    //write results to file
    initial begin
        results_file= $fopen("../../../../../HDL_testbenches/testbench_vivoutput_Q.txt","w");
        if (results_file==0) begin
            $display("Could not open file testbench_vivoutput_I.txt");
            $stop;     
        end
        while (simulation_running) begin
            //wait for clk edge, then check if data out is valid. If yes, write to file
            @(posedge clk_gen);
            if(data_valid_chk) begin
                $fwrite(results_file,"0x%h\n",I_data_chk);
            end
        end
        $fclose(results_file);
    end

  //  //write results to file
  //  initial begin
  //      results_file_2= $fopen("../../../../../HDL_testbenches/testbench_vivoutput_Q.txt","w");
  //      if (results_file_2==0) begin
  //          $display("Could not open file testbench_vivoutput_Q.txt");
  //          $stop;     
  //      end
  //      while (simulation_running) begin
  //          //wait for clk edge, then check if data out is valid. If yes, write to file
  //          @(posedge clk_gen);
  //          if(data_valid_chk) begin
  //              $fwrite(results_file_2,"0x%h\n",Q_data_chk);
  //          end
  //      end
  //      $fclose(results_file_2);
  // end
	
endmodule
