/// Description: Requantization, keeps only N MSBs of the input sample

/// Author: Alkinoos Sarioglou <asarioglou@student.ethz.ch>

module requantizer #(
    parameter int unsigned Data_bits = 10,
    parameter int unsigned Requantized_bits = 6
  ) (
    input  	logic [Data_bits-1:0] 	        data_in,
    input  	logic			                      data_valid_i,
    input	  logic			                      clk_i,
    input	  logic			                      rst_ni,		
    output 	logic [Requantized_bits-1:0] 	  data_out,
    output  logic			                      data_valid_o
  );

  // Internal signals
  logic [Requantized_bits-1:0]  data_d, data_q;
  logic                         data_valid_d, data_valid_q;

  // Combinational logic
  always_comb begin

    data_d = data_q;

    if (data_valid_i) begin
      data_d       = data_in[Data_bits-1 -: Requantized_bits];
      data_valid_d = 1'b1;
	  end else begin
      data_valid_d = 1'b0;
    end

  end

  // Sequential elements

  always_ff @(posedge clk_i or negedge rst_ni) begin: p_data_q
    if (!rst_ni) begin
      data_q <= '0;
    end else begin
      data_q <= data_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data_valid_q
    if(~rst_ni) begin
      data_valid_q <= 0;
    end else begin
      data_valid_q <= data_valid_d;
    end
  end

  // Output assignment
  assign data_out     = data_q;
  assign data_valid_o = data_valid_q;



endmodule : requantizer
