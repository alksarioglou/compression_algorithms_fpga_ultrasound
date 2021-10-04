/// Description: Decimator, keeps every nth sample

/// Author: Alkinoos Sarioglou <asarioglou@student.ethz.ch>

module decimator #(
    parameter int unsigned Decimation_factor = 8, // Decimation factor
    parameter int unsigned Data_bits = 10
  ) (
    input   logic [Data_bits-1:0]   data_in,
    input   logic                   data_valid_i,
    input   logic                   clk_i,
    input   logic                   rst_ni,   
    output  logic [Data_bits-1:0]   data_out,
    output  logic                   data_valid_o
  );

  // Input and Output of FF
  logic [Data_bits-1:0]  input_data_ff, output_data_ff;

  // Control signals
  logic comp_out;

  logic [$clog2(Decimation_factor)-1:0] count_d, count_q;

  // FSM states
  typedef enum logic { IDLE, RUN } state_t;
  state_t state_d, state_q;

  // COMBINATORIAL LOGIC


  /*********
   *  FSM  *
   *********/

  always_comb begin
    input_data_ff = $signed(data_in);
  end

  always_comb begin: fsm_proc
    
    // Default assignments
    state_d          = state_q;
    comp_out         = 1'b0;
    count_d          = count_q;

    case (state_q)

      IDLE: begin

        if (data_valid_i) begin
          state_d = RUN;
        end

      end

      RUN: begin

        if (count_q == Decimation_factor - 1) begin
          comp_out  = 1'b1;
          count_d   = '0;
          state_d   = IDLE;
        end else begin
          comp_out  = 1'b0;
          count_d = count_q + 1;
          state_d = IDLE;
        end

      end

    endcase

  end

  // Sequential elements

  always_ff @(posedge clk_i or negedge rst_ni) begin: p_state_q
    if (!rst_ni) begin
      state_q <= IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_count_q 
    if(~rst_ni) begin
      count_q  <= Decimation_factor - 1;
    end else begin
      count_q  <= count_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_output_data_ff 
    if(~rst_ni) begin
      output_data_ff  <= '0;
    end else begin
      output_data_ff  <= input_data_ff;
    end
  end

  // Output assignment
  assign data_out = $signed(output_data_ff);
  assign data_valid_o = comp_out ? 1'b1 : 1'b0;

endmodule : decimator