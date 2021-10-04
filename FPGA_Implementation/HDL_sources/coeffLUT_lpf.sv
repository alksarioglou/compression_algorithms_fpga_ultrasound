// Description: Coefficient LUT table to save the coefficients of an FIR filter

// Author: Alkinoos Sarioglou (asarioglou@student.ethz.ch)

module coeffLUT_lpf #(
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
16'h007f,
16'h00f2,
16'h01b6,
16'h02bc,
16'h03fa,
16'h055b,
16'h06c4,
16'h0811,
16'h091f,
16'h09cf,
16'h0a0c,
16'h09cf,
16'h091f,
16'h0811,
16'h06c4,
16'h055b,
16'h03fa,
16'h02bc,
16'h01b6,
16'h00f2,
16'h007f}; // first coeff is in addr=Order, last coeff is in addr=0

	// Output assignment
	assign data_o = $signed(data_q);

endmodule