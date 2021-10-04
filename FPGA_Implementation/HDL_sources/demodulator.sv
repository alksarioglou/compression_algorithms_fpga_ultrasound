/// Description: Demodulator, performs demodulation in the input RF data
/// and outputs IQ data

/// Author: Alkinoos Sarioglou <asarioglou@student.ethz.ch>

module demodulator #(
    parameter shortreal          Freq_carrier  = 5*(10**6), // Transducer carrier frequency
    parameter shortreal          Freq_sampling = 20*(10**6), // Sampling frequency
    parameter int       unsigned Data_bits     = 10,
    parameter int       unsigned Coeff_bits    = 16
  ) (
    input  	logic [Data_bits-1:0] 	data_in,
    input  	logic			              data_valid_i,
    input	  logic			              clk_i,
    input	  logic			              rst_ni,
    output  logic     		          I_data_valid_o,
    output  logic                   Q_data_valid_o,
    output 	logic [Data_bits-1:0] 	I_data_out,
    output  logic [Data_bits-1:0]   Q_data_out
  );

  // Sine and Cosine functions LUT
  // Internal signal specification
  // Need to represent only a limited amount of numbers
  localparam int unsigned   No_values_in_function = Freq_sampling/Freq_carrier;
  localparam int unsigned   AddrWidth = $clog2(No_values_in_function);

  // Coefficient Table Specification
  typedef logic [Coeff_bits-1:0] element;
  element [No_values_in_function-1:0] sine_coeff_table;
  element [No_values_in_function-1:0] cosine_coeff_table;

  logic [Coeff_bits-1:0]         current_sine_value;
  logic [Coeff_bits-1:0]         current_cosine_value;

  assign sine_coeff_table   = '{2**(Coeff_bits-1)-1, 0, -2**(Coeff_bits-1), 0};  // when no_values_in_function = 4 - VALUES REVERSED
  //assign sine_coeff_table   = '{-(2**(Coeff_bits-1))/2, -2**(Coeff_bits-1), -(2**(Coeff_bits-1))/2, 0, (2**(Coeff_bits-1)-1)/2, 2**(Coeff_bits-1)-1, (2**(Coeff_bits-1)-1)/2 ,0};  // when no_values_in_function = 4 - VALUES REVERSED
  
  //assign cosine_coeff_table = '{(2**(Coeff_bits-1)-1)/2, 0, -(2**(Coeff_bits-1))/2, -2**(Coeff_bits-1), -(2**(Coeff_bits-1))/2, 0, (2**(Coeff_bits-1)-1)/2 , 2**(Coeff_bits-1)-1};  // when no_values_in_function = 4 - VALUES REVERSED
  assign cosine_coeff_table = '{0, -2**(Coeff_bits-1), 0, 2**(Coeff_bits-1)-1};  // when no_values_in_function = 4 - VALUES REVERSED
  // Internal signals
  logic ren_lut_i, out_en;

  // Addresses
  logic [AddrWidth-1:0] sine_addr_lut_d, sine_addr_lut_q;
  logic [AddrWidth-1:0] cosine_addr_lut_d, cosine_addr_lut_q;

  // FSM states
  typedef enum logic [1:0] { IDLE, RUN, PROVIDE } state_t;
  state_t state_d, state_q;

  // Multiplication variables
  logic [Data_bits+Coeff_bits-1:0] sine_mult_result_d, sine_mult_result_q;
  logic [Data_bits+Coeff_bits-1:0] cosine_mult_result_d, cosine_mult_result_q;

  // COMBINATORIAL LOGIC

  // Address Generation - Sine Wave
  always_comb begin

    sine_addr_lut_d = sine_addr_lut_q;

    if (ren_lut_i) begin
      if (sine_addr_lut_q == No_values_in_function-1) begin
        sine_addr_lut_d = '0;
      end else begin
        sine_addr_lut_d = sine_addr_lut_q + 1;
      end
    end
  end


  // Address Generation - Cosine Wave
  always_comb begin

    cosine_addr_lut_d = cosine_addr_lut_q;

    if (ren_lut_i) begin
      if (cosine_addr_lut_q == No_values_in_function-1) begin
        cosine_addr_lut_d = '0;
      end else begin
        cosine_addr_lut_d = cosine_addr_lut_q + 1;
      end
    end
  end

  
  // Multiplication operations
  always_comb begin

    sine_mult_result_d   = sine_mult_result_q;
    cosine_mult_result_d = cosine_mult_result_q;

    current_sine_value   = sine_coeff_table[sine_addr_lut_q];
    current_cosine_value = cosine_coeff_table[cosine_addr_lut_q];


    if (ren_lut_i) begin
      sine_mult_result_d   = 2 * $signed(data_in) * $signed(current_sine_value);
      cosine_mult_result_d = 2 * $signed(data_in) * $signed(current_cosine_value);
    end

  end


  /*********
   *  FSM  *
   *********/

  always_comb begin: fsm_proc
    
    // Default assignments
    state_d          = state_q;
    ren_lut_i        = 1'b0;
    out_en           = 1'b0;
    I_data_valid_o   = 1'b0;
    Q_data_valid_o   = 1'b0;

    case (state_q)

      IDLE: begin
        ren_lut_i       = 1'b0;
        out_en          = 1'b0;
        I_data_valid_o  = 1'b0;
        Q_data_valid_o  = 1'b0;
        if (data_valid_i) begin
          state_d = RUN;
        end
      end

      RUN: begin
        ren_lut_i       = 1'b1;
        out_en          = 1'b0;
        I_data_valid_o  = 1'b0;
        Q_data_valid_o  = 1'b0;
        state_d         = PROVIDE;
      end

      PROVIDE: begin
        ren_lut_i        = 1'b0;
        out_en           = 1'b1;
        I_data_valid_o   = 1'b1;
        Q_data_valid_o   = 1'b1;
        state_d          = IDLE;
      end
    endcase
  end


// Sequential elements

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_sine_mult_result_q 
    if(~rst_ni) begin
      sine_mult_result_q  <= 0;
    end else begin
      sine_mult_result_q  <= sine_mult_result_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_cosine_mult_result_q 
    if(~rst_ni) begin
      cosine_mult_result_q  <= 0;
    end else begin
      cosine_mult_result_q  <= cosine_mult_result_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_sine_addr_lut_q 
    if(~rst_ni) begin
      sine_addr_lut_q  <= 0;
    end else begin
      sine_addr_lut_q  <= sine_addr_lut_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_cosine_addr_lut_q 
    if(~rst_ni) begin
      cosine_addr_lut_q  <= 0;
    end else begin
      cosine_addr_lut_q  <= cosine_addr_lut_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin: p_state_q
    if (!rst_ni) begin
      state_q <= IDLE;
    end else begin
      state_q <= state_d;
    end
  end


  // Output assignments
  assign I_data_out     = $signed(cosine_mult_result_q[Data_bits+Coeff_bits-1 -: Data_bits]);
  assign Q_data_out     = $signed(sine_mult_result_q[Data_bits+Coeff_bits-1 -: Data_bits]);

endmodule : demodulator