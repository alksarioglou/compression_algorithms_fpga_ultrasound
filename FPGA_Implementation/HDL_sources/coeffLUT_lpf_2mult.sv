// Description: Coefficient LUT table to save coefficients
// for an implementation of an FIR filter with
// 2 multiplications/cycle

// Author: Alkinoos Sarioglou (asarioglou@student.ethz.ch)

module coeffLUT_lpf_2mult #(
    parameter int unsigned DataWidth = 10, // Data Width
    parameter int unsigned Taps = 101      // No. of Taps
  ) (
  	input  logic clk_i,
  	input  logic rst_ni,
    input  logic ren_i,
    input  logic [$clog2(Taps)-1:0] addr1_i, // Read address 1
    input  logic [$clog2(Taps)-1:0] addr2_i, // Read address 2
    output logic [DataWidth-1:0] data_o1,    // Output 1
    output logic [DataWidth-1:0] data_o2     // Output 2
  );

  // Internal signal specification
  logic [DataWidth-1:0] data_q1, data_q2;
  localparam            AddrWidth = $clog2(Taps);

  // Coefficient Table Specification
  typedef logic [DataWidth-1:0] element;
  element [Taps-1:0] coeff_table;

  // Write output data
  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data_q1
  	if(~rst_ni) begin
  		data_q1 <= 0;
  	end else begin
  		data_q1 <= $signed(coeff_table[addr1_i]);
  	end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data_q2
    if(~rst_ni) begin
      data_q2 <= 0;
    end else begin
      data_q2 <= $signed(coeff_table[addr2_i]);
    end
  end

  // Initialize coefficient table
	assign coeff_table = '{
16'h017b,
16'h0016,
16'hfec8,
16'hfc4e,
16'hf8a7,
16'hf424,
16'hef76,
16'hebae,
16'hea1b,
16'hec15,
16'hf2b6,
16'hfe97,
16'h0f95,
16'h24b3,
16'h3c29,
16'h5392,
16'h6844,
16'h77bb,
16'h7fff,
16'h7fff,
16'h77bb,
16'h6844,
16'h5392,
16'h3c29,
16'h24b3,
16'h0f95,
16'hfe97,
16'hf2b6,
16'hec15,
16'hea1b,
16'hebae,
16'hef76,
16'hf424,
16'hf8a7,
16'hfc4e,
16'hfec8,
16'h0016,
16'h017b
}; // first coeff is in addr=Order, last coeff is in addr=0

	// Output assignment
	assign data_o1 = $signed(data_q1);
  assign data_o2 = $signed(data_q2);

endmodule