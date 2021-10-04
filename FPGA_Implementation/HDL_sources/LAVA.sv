/// Description: LAVA, performs the LAVA algorithm
/// NOTE: NEEDS DEBUGGING AS IT HAS NOT BEEN TESTED YET

/// Author: Alkinoos Sarioglou <asarioglou@student.ethz.ch>

module LAVA #(
    parameter int unsigned Data_bits  = 10,
    parameter int unsigned Threshold  = 20,
    parameter int unsigned Samples_per_channel = 3328
  ) (
    input  	logic [Data_bits-1:0] 	              data_in,
    input  	logic			                            data_valid_i,
    input	  logic			                            clk_i,
    input	  logic			                            rst_ni,		
    output 	logic [Data_bits+$clog2(Samples_per_channel)-1:0] 	  data_out,
    output  logic			                            data_valid_o
  );

  // For indexes
  localparam             Index_width = $clog2(Samples_per_channel);

  // Internal signals
  logic [Data_bits-1:0]   reg_value_d, reg_value_q;
  logic [Index_width-1:0] index_d, index_q;
  logic                   valid_o_d, valid_o_q;


  // Combinational logic
  always_comb begin

    reg_value_d = reg_value_q;
    valid_o_d   = valid_o_q;

    if (data_valid_i) begin
      if (data_in > reg_value_q) begin
        if (data_in - reg_value_q >= Threshold) begin
          reg_value_d = data_in;
          valid_o_d   = 1'b1;
        end else begin
          valid_o_d   = 1'b0;
        end
      end else begin
        if (reg_value_q - data_in >= Threshold) begin
          reg_value_d = data_in;
          valid_o_d   = 1'b1;
        end else begin
          valid_o_d   = 1'b0;
        end
      end
    end

  end

  always_comb begin

    index_d = index_q;

    if (data_valid_i) begin
      index_d = index_q + 1;

      if (index_d == Samples_per_channel) begin
        index_d = '0;
      end

    end

  end

  // Sequential elements

  always_ff @(posedge clk_i or negedge rst_ni) begin: p_reg_value_q
    if (!rst_ni) begin
      reg_value_q <= '0;
    end else begin
      reg_value_q <= reg_value_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin: p_index_q
    if (!rst_ni) begin
      index_q <= '0;
    end else begin
      index_q <= index_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin: p_valid_o_q
    if (!rst_ni) begin
      valid_o_q <= '0;
    end else begin
      valid_o_q <= valid_o_d;
    end
  end


  // Output assignment
  assign data_out     = {reg_value_q, index_q};
  assign data_valid_o = valid_o_q;



endmodule : LAVA
