`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Alkinoos Sarioglou (asarioglou@student.ethz.ch)
// 
// Create Date: 20.04.2021 23:37:08
// Design Name: 
// Module Name: compression_module
// Project Name: Data Reduction of Ultrasound Signals on FPGA
// Target Devices: Artix-7 FPGA XC7A100T
// Tool Versions: 
// Description: Compression algorithm combination module, which is used
// in the final implementation of the compression algorithm module with all
// of the 32 channels (compression_signal_processing_parallel.sv) 
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module compression_module #(
    parameter int unsigned  Data_width = 10,
    parameter int unsigned  Requantized_bits = 6,
    parameter int unsigned  LAVA_Threshold = 10,
    parameter int unsigned  Samples_per_channel = 3328,
    parameter int unsigned  Coeff_bits = 16,
    parameter int unsigned  Order_hpf = 18, // HPF order
    parameter shortreal     Cut_off_hpf = 1*(10**6), // HPF cut-off frequency
    parameter shortreal     Freq_carrier = 5*(10**6), // Transducer carrier frequency
    parameter shortreal     Freq_sampling = 20*(10**6), // Sampling frequency
    parameter int unsigned  Order_lpf = 37, // LPF order
    parameter int unsigned  Decimation_factor = 2

)(
    input  logic                     clk_i,
    input  logic                     reset_ni,
    input  logic [Data_width-1:0]    data_i,    // change it to [319:0]
    input  logic                     data_valid_i,
    output logic [Data_width-1:0]    I_data_o,
    // for LAVA: output logic [Data_width+$clog2(Samples_per_channel)-1:0]    I_data_o,  // For I data
    output logic [Data_width-1:0]    Q_data_o,  // For Q data
    output logic                     data_valid_o
    );

    // Signal declarations

    // For High-Pass Filter
    logic [Data_width-1:0]     data_out_hpf; // change it to [319:0]
    logic                      data_valid_o_hpf;

    // For Demodulator
    logic [Data_width-1:0]     I_data_out_demod, Q_data_out_demod; // change it to [319:0]
    logic                      I_data_valid_o_dem, Q_data_valid_o_dem;

    // For Decimator
    logic [Data_width-1:0]     I_data_out_dec, Q_data_out_dec;
    logic                      I_data_valid_o_dec, Q_data_valid_o_dec;
    logic                      I_data_valid_o, Q_data_valid_o;

    // For Low-Pass Filter
    localparam                 Cut_off_lpf = (20*(10**6))/Decimation_factor;
    logic [Data_width-1:0]     I_data_out_lpf, Q_data_out_lpf;  // change it to [319:0]
    logic                      I_data_valid_o_lpf, Q_data_valid_o_lpf;
    
    // For Requantizer
    logic                           I_data_valid_req_o;
    logic [Requantized_bits-1:0]    I_data_req_o;

    // For LAVA
    localparam                      Index_width = $clog2(Samples_per_channel);
    
    
    // // Module instantiations
   
    // High-pass filter with cut-off 1 MHz
    hpf_filter #(
        .Order(Order_hpf),
        .Data_bits(Data_width),
        .Coeff_bits(Coeff_bits)
      ) i_hpf (
        .data_in(data_i),
        .data_valid_i(data_valid_i),
        .clk_i(clk_i),
        .rst_ni(reset_ni),
        .data_valid_o(data_valid_o_hpf),
        .data_out(data_out_hpf)
    );

    // Demodulator with carrier frequency fc
    demodulator #(
        .Freq_carrier(Freq_carrier),
        .Freq_sampling(Freq_sampling),
        .Data_bits(Data_width),
        .Coeff_bits(Coeff_bits)
      ) i_demodulator (
        .data_in(data_out_hpf),
        .data_valid_i(data_valid_o_hpf),
        .clk_i(clk_i),
        .rst_ni(reset_ni),
        .I_data_valid_o(I_data_valid_o_dem),
        .Q_data_valid_o(Q_data_valid_o_dem),
        .I_data_out(I_data_out_demod),
        .Q_data_out(Q_data_out_demod)
    );

    // NEEDS DEBUGGING, PLEASE LOOK INSIDE THE MODULE
    // Low-Pass Filter for I data with cut-off sampling_freq/decimation_factor
    lpf_filter_mult2 #(
        .Order(Order_lpf),
        .Data_bits(Data_width),
        .Coeff_bits(Coeff_bits)
      ) i_lpf_I (
        .data_in(I_data_out_demod),
        .data_valid_i(I_data_valid_o_dem),
        .clk_i(clk_i),
        .rst_ni(reset_ni),
        .data_valid_o(I_data_valid_o_lpf),
        .data_out(I_data_out_lpf)
    );

    // NEEDS DEBUGGING, PLEASE LOOK INSIDE THE MODULE
    // Low-Pass Filter for Q data with cut-off sampling_freq/decimation_factor
    lpf_filter_mult2 #(
        .Order(Order_lpf),
        .Data_bits(Data_width),
        .Coeff_bits(Coeff_bits)
      ) i_lpf_Q (
        .data_in(Q_data_out_demod),
        .data_valid_i(Q_data_valid_o_dem),
        .clk_i(clk_i),
        .rst_ni(reset_ni),
        .data_valid_o(Q_data_valid_o_lpf),
        .data_out(Q_data_out_lpf)
    );

    // Decimator for I data
    decimator #(
        .Decimation_factor(Decimation_factor),
        .Data_bits(Data_width)
      ) i_decimator_I (
        .data_in(I_data_out_lpf),
        .data_valid_i(I_data_valid_o_lpf),
        .clk_i(clk_i),
        .rst_ni(reset_ni),
        .data_valid_o(I_data_valid_o),
        .data_out(I_data_o)
    );

    // Decimator for Q data
    decimator #(
        .Decimation_factor(Decimation_factor),
        .Data_bits(Data_width)
      ) i_decimator_Q (
        .data_in(Q_data_out_lpf),
        .data_valid_i(Q_data_valid_o_lpf),
        .clk_i(clk_i),
        .rst_ni(reset_ni),
        .data_valid_o(Q_data_valid_o),
        .data_out(Q_data_o)
    );

    // requantizer #(
    //     .Data_bits(Data_width),
    //     .Requantized_bits(Requantized_bits)
    // ) i_requantizer_I (
    //     .data_in     (data_i),//(I_data_dec_o),
    //     .data_valid_i(data_valid_i),//(I_data_dec_valid_o),
    //     .clk_i       (clk_i),
    //     .rst_ni      (reset_ni),
    //     .data_valid_o(I_data_valid_req_o),
    //     .data_out    (I_data_req_o)
    // );

    // requantizer #(
    //     .Data_bits(Data_width),
    //     .Requantized_bits(Requantized_bits)
    // ) i_requantizer_Q (
    //     .data_in     (Q_data_dec_o),
    //     .data_valid_i(Q_data_dec_valid_o),
    //     .clk_i       (clk_i),
    //     .rst_ni      (reset_ni),
    //     .data_valid_o(Q_data_valid_req_o),
    //     .data_out    (Q_data_req_o)
    // );

    // LAVA #(
    //     .Data_bits(Data_width),
    //     .Threshold(10),
    //     .Samples_per_channel(Samples_per_channel)
    // ) i_LAVA_I (
    //     .data_in     (data_i),
    //     .data_valid_i(data_valid_i),
    //     .clk_i       (clk_i),
    //     .rst_ni      (reset_ni),
    //     .data_valid_o(I_data_valid_o),
    //     .data_out    (I_data_o)
    // );

    // LAVA #(
    //     .Data_bits(Data_width),
    //     .Threshold(20)
    // ) i_LAVA_Q (
    //     .data_in     (Q_data_req_o),
    //     .data_valid_i(Q_data_valid_req_o),
    //     .clk_i       (clk_i),
    //     .rst_ni      (reset_ni),
    //     .data_valid_o(Q_data_valid_o),
    //     .data_out    (Q_data_o)
    // );


    // Output assignment
	assign data_valid_o = I_data_valid_o && Q_data_valid_o;
    //assign data_valid_o = I_data_valid_o;
    //assign I_data_o = I_data_req_o;

	
endmodule