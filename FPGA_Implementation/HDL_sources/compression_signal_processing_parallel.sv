`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Alkinoos Sarioglou (asarioglou@student.ethz.ch)
// 
// Create Date: 20.04.2021 23:37:08
// Design Name: 
// Module Name: compression_signal_processing_parallel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Implementation of the compression algorithm module
// which includes all the 32 channels
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: Create 32 channels of the compression block
// 
//////////////////////////////////////////////////////////////////////////////////


module compression_signal_processing_parallel #(
    parameter int unsigned  Data_width = 10,
    parameter int unsigned  No_channels = 128,
    parameter int unsigned  Requantized_bits = 6,
    parameter int unsigned  LAVA_Threshold = 10,
    parameter int unsigned  Samples_per_channel = 3328,
    parameter int unsigned  Coeff_bits = 16,
    parameter int unsigned  Order_hpf = 18, // HPF order
    parameter shortreal     Cut_off_hpf = 1*(10**6), // HPF cut-off frequency
    parameter shortreal     Freq_carrier = 5*(10**6), // Transducer carrier frequency
    parameter shortreal     Freq_sampling = 20*(10**6), // Sampling frequency
    parameter int unsigned  Order_lpf = 37, // LPF order
    parameter int unsigned  Decimation_factor = 8

)(
    input  logic                                 clk_i,
    input  logic                                 reset_ni,
    input  logic [Data_width*No_channels-1:0]    data_i,    // change it to [319:0]
    input  logic                                 data_valid_i,
    output logic [Data_width*No_channels-1:0]    I_data_o,
    // for LAVA: output logic [Data_width+$clog2(Samples_per_channel)-1:0]    I_data_o,  // For I data
    output logic [Data_width*No_channels-1:0]    Q_data_o,  // For Q data
    output logic                                 data_valid_o
    );
    
    // Internal signals
    genvar i;
    
    // // Module instantiations

    generate
        for (i = 0; i < No_channels; i++) begin
            
            // Compression module
            compression_module # (
                .Data_width         (Data_width),
                .Requantized_bits   (Requantized_bits),
                .LAVA_Threshold     (LAVA_Threshold),
                .Samples_per_channel(Samples_per_channel),
                .Coeff_bits         (Coeff_bits),
                .Order_hpf          (Order_hpf),
                .Cut_off_hpf        (Cut_off_hpf),
                .Freq_carrier       (Freq_carrier),
                .Freq_sampling      (Freq_sampling),
                .Order_lpf          (Order_lpf),
                .Decimation_factor  (Decimation_factor)

            ) i_compr_module (
                .clk_i       (clk_i),
                .reset_ni    (reset_ni),
                .data_i      (data_i[10*i+9:10*i]),
                .data_valid_i(data_valid_i),
                .I_data_o    (I_data_o[10*i+9:10*i]),
                .Q_data_o    (Q_data_o[10*i+9:10*i]),
                .data_valid_o(data_valid_o)

            );

        end
    endgenerate
   


	
endmodule
