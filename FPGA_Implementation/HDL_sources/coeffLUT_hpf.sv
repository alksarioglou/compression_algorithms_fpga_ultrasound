// Coefficient LUT table to save coefficients of a FIR filter

// Author: Alkinoos Sarioglou (asarioglou@student.ethz.ch)

module coeffLUT_hpf #(
    parameter int unsigned DataWidth = 10, // Data Width
    parameter int unsigned Taps = 101   // No. of Taps
  ) (
  	input  logic clk_i,
  	input  logic rst_ni,
    input  logic ren_i,
    input  logic [$clog2(Taps)-1:0] addr_i,
    output logic [DataWidth-1:0] data_o
  );

  // Internal signal specification
  logic [DataWidth-1:0] data_q;
  localparam            AddrWidth = $clog2(Taps);

  // Coefficient Table Specification
  typedef logic [DataWidth-1:0] element;
  element [Taps-1:0] coeff_table;

  // Write output data
  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data_q
  	if(~rst_ni) begin
  		data_q <= 0;
  	end else begin
  		data_q <= $signed(coeff_table[addr_i]);
  	end
  end

  // Initialize coefficient table
  assign coeff_table = '{
16'h02d9,                                                     
16'hfd06,                                                     
16'h0447,                                                     
16'hfa4b,                                                     
16'h072e,                                                     
16'hf769,                                                     
16'h09d5,                                                     
16'hf532,                                                     
16'h0b6c,                                                     
16'h7fff,                                                     
16'h0b6c,                                                     
16'hf532,                                                     
16'h09d5,                                                     
16'hf769,                                                     
16'h072e,                                                     
16'hfa4b,                                                     
16'h0447,                                                     
16'hfd06,                                                     
16'h02d9  }; // first coeff is in addr=Order, last coeff is in addr=0


	// Output assignment
	assign data_o = $signed(data_q);

endmodule