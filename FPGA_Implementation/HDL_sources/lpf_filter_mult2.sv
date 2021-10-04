/// Description: FIR filter used as a Low-Pass Filter
// Implementation of an FIR filter with
// 2 multiplications/cycle

/// NEEDS DEBUGGING! (see inside the code for more specific parts which need debugging)

/// Author: Alkinoos Sarioglou <asarioglou@student.ethz.ch>

module lpf_filter_mult2 #(
    parameter int unsigned Order = 2, // Order
    parameter int unsigned Data_bits = 10,
    parameter int unsigned Coeff_bits = 10
  ) (
    input  	logic [Data_bits-1:0] 	  data_in,
    input  	logic			                data_valid_i,
    input   logic                     hpf_check,
    input	  logic			                clk_i,
    input	  logic			                rst_ni,		
    output 	logic [Data_bits-1:0]     data_out,
    output  logic			                data_valid_o
  );

  // Local parameters
  localparam  AddrWidth = $clog2(Order+1);

  // MAC internal signals
  logic        acc_clear;

  logic [Data_bits+Coeff_bits-1:0] mult1_result, mult2_result;
  logic [Data_bits+Coeff_bits-1:0] mac_result_d, mac_result_q;

  // FSM states
  typedef enum logic [1:0] { IDLE, LOAD, RUN, PROVIDE } state_t;
  state_t state_d, state_q;

  // Addresses
  logic [AddrWidth-1:0] lut_rd_addr1_d, lut_rd_addr1_q;
  logic [AddrWidth-1:0] ram_rd_addr1_d, ram_rd_addr1_q;
  logic [AddrWidth-1:0] lut_rd_addr2_d, lut_rd_addr2_q;
  logic [AddrWidth-1:0] ram_rd_addr2_d, ram_rd_addr2_q;
  logic [AddrWidth-1:0] ram_wr_addr_d, ram_wr_addr_q;

  // Output register
  logic                            out_reg_en;
  logic [Data_bits-1:0]            out_reg_d, out_reg_q;
  
  // Internal signals
  logic ren_i, wen_i;
  logic [Data_bits-1:0]  ram_output1, ram_output2;
  logic [Coeff_bits-1:0] lut_output1, lut_output2;



  // Modules instantiation
  samples_ram_2mult # (
    .AddrWidth(AddrWidth),
    .DataWidth(Data_bits)
  ) i_ram_2mult (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .ren_i       (ren_i),
    .wen_i       (wen_i),
    .rd_addr1_i  (ram_rd_addr1_q),
    .rd_addr2_i  (ram_rd_addr2_q),
    .wr_addr_i   (ram_wr_addr_q),
    .data_i      (data_in),
    .data_o1     (ram_output1),
    .data_o2     (ram_output2)
  );

  coeffLUT_lpf_2mult # (
    .DataWidth(Coeff_bits),
    .Taps(Order+1)
  ) i_coeffLUT_2mult (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .ren_i      (ren_i),
    .addr1_i    (lut_rd_addr1_q),
    .addr2_i    (lut_rd_addr2_q),
    .data_o1    (lut_output1),
    .data_o2    (lut_output2)
  );

  // MAC operation

  always_comb begin

    mac_result_d = mac_result_q;

    if (acc_clear) begin
      mac_result_d  = '0;
      mult1_result  = '0;
      mult2_result  = '0;
    end else if (state_q == RUN) begin
      mult1_result = 2 * $signed(ram_output1) * $signed(lut_output1);
      mult2_result = 2 * $signed(ram_output2) * $signed(lut_output2);
      mac_result_d = $signed(mac_result_q) + $signed(mult1_result) + $signed(mult2_result);
    end
  end

  assign out_reg_d = $signed(mac_result_d[Data_bits+Coeff_bits-1 -: Data_bits]);


  // ADDRESS GENERATION

  // NEEDS DEBUGGING
  // CoeffLUT address generation
  always_comb begin

    lut_rd_addr1_d = lut_rd_addr1_q;

    if (ren_i) begin
      if (lut_rd_addr1_q >= Order) begin
        lut_rd_addr1_d = '0;
      end else if (lut_rd_addr1_q == Order - 1) begin
        lut_rd_addr1_d = '0;
      end else begin
        lut_rd_addr1_d = lut_rd_addr1_q + 2;
      end
    end else if (state_q == PROVIDE) begin
        lut_rd_addr1_d = '0;
    end
  end

  always_comb begin

    lut_rd_addr2_d = lut_rd_addr2_q;

    if (ren_i) begin
      if (lut_rd_addr2_q >= Order) begin
        lut_rd_addr2_d = 'd1;
      end else if (lut_rd_addr2_q == Order - 1) begin
        lut_rd_addr2_d = 'd1;
      end else begin
        lut_rd_addr2_d = lut_rd_addr2_q + 2;
      end
    end else if (state_q == PROVIDE) begin
        lut_rd_addr2_d = 'd1;
    end
  end


  // NEEDS DEBUGGING
  // RAM read address generation
  always_comb begin

    ram_rd_addr1_d = ram_rd_addr1_q;

    if (ren_i) begin
        ram_rd_addr1_d = ram_rd_addr1_q - 2;
    end else if (wen_i) begin   // Correct update of the RAM read address
      ram_rd_addr1_d = ram_wr_addr_q;
    end
  end

  always_comb begin

    ram_rd_addr2_d = ram_rd_addr2_q;

    if (ren_i) begin
        ram_rd_addr2_d = ram_rd_addr2_q - 2;
    end else if (wen_i) begin   // Correct update of the RAM read address
      ram_rd_addr2_d = ram_wr_addr_q - 1;
    end
  end


  // NEEDS DEBUGGING
  // RAM write address generation
  always_comb begin

    ram_wr_addr_d = ram_wr_addr_q;

    if (wen_i) begin
      if (ram_wr_addr_q == Order) begin
        ram_wr_addr_d = '0;
      end else begin
        ram_wr_addr_d = ram_wr_addr_q + 1;
      end
    end
  end


  /*********
   *  FSM  *
   *********/

  always_comb begin: fsm_proc
    
    // Default assignments
    state_d        = state_q;
    acc_clear      = 1'b0;
    ren_i          = 1'b0;
    wen_i          = 1'b0;
    out_reg_en     = 1'b0;
    data_valid_o   = 1'b0;

    case (state_q)
      IDLE: begin
        acc_clear = 1'b1;
        if (data_valid_i) begin
          state_d = LOAD;
          wen_i   = 1'b1;
        end
      end

      LOAD: begin
        wen_i         = 1'b0;
        acc_clear     = 1'b1;
        ren_i         = 1'b1;
        state_d       = RUN;
        
      end

      RUN: begin
        wen_i     = 1'b0;
        acc_clear = 1'b0;
        ren_i     = 1'b1;
        // NEEDS DEBUGGING
        if ((lut_rd_addr1_q == '0) || (lut_rd_addr2_q == 'd0)) begin
          state_d        = PROVIDE;
          ren_i          = 1'b0;
        end
      end

      PROVIDE: begin
        out_reg_en     = 1'b1;
        data_valid_o = 1'b1;
        if(hpf_check) begin
          state_d = IDLE;
        end
      end
    endcase
  end




  // SEQUENTIAL ELEMENTS

  always_ff @(posedge clk_i or negedge rst_ni) begin: p_state_q
    if (!rst_ni) begin
      state_q <= IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_mac_result_q
    if(~rst_ni) begin
      mac_result_q <= 0;
    end else begin
      mac_result_q <= mac_result_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_lut_rd_addr1_d
    if(~rst_ni) begin
      lut_rd_addr1_q <= 0;
    end else begin
      lut_rd_addr1_q <= lut_rd_addr1_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_lut_rd_addr2_d
    if(~rst_ni) begin
      lut_rd_addr2_q <= 'd1;
    end else begin
      lut_rd_addr2_q <= lut_rd_addr2_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ram_rd_addr1_q
    if(~rst_ni) begin
      ram_rd_addr1_q <= 0;
    end else begin
      ram_rd_addr1_q <= ram_rd_addr1_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ram_rd_addr2_q
    if(~rst_ni) begin
      ram_rd_addr2_q <= Order;
    end else begin
      ram_rd_addr2_q <= ram_rd_addr2_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ram_wr_addr_q
    if(~rst_ni) begin
      ram_wr_addr_q <= 0;
    end else begin
      ram_wr_addr_q <= ram_wr_addr_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_out_reg_q
    if(~rst_ni) begin
      out_reg_q <= 0;
    end else begin
      if (state_d == PROVIDE) begin
        out_reg_q <= out_reg_d;
      end
    end
  end

  // Output assignment

	assign data_out = $signed(out_reg_q);

endmodule : lpf_filter_mult2
