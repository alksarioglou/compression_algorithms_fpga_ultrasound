/// Description: RAM module for storage of data samples in filter
/// implementation with 2 multiplications/cycle

/// Author: Alkinoos Sarioglou <asarioglou@student.ethz.ch>

module samples_ram_2mult #(
    parameter int unsigned DataWidth = 18, // Data Width
    parameter int unsigned AddrWidth = 7   // Address Width
  ) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 ren_i,
    input  logic                 wen_i,
    input  logic [AddrWidth-1:0] rd_addr1_i,
    input  logic [AddrWidth-1:0] rd_addr2_i,
    input  logic [AddrWidth-1:0] wr_addr_i,
    input  logic [DataWidth-1:0] data_i,
    output logic [DataWidth-1:0] data_o1,
    output logic [DataWidth-1:0] data_o2

  );



  // Specification of RAM memory
  typedef logic [DataWidth-1:0] element;
  element [2**AddrWidth-1:0]    ram;

  logic [DataWidth-1:0]         data_q1, data_q2;

  // Write functionality
  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_ram
    if(~rst_ni) begin
      ram <= '{default: '0};
    end else begin
      if (wen_i) begin
        ram[wr_addr_i] <= $signed(data_i);
      end
    end
  end


  // Read functionality
  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data1_out
    if(~rst_ni) begin
      data_q1 <= '0;
    end else begin
      if (ren_i) begin
        data_q1 <= $signed(ram[rd_addr1_i]);
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data2_out
    if(~rst_ni) begin
      data_q2 <= '0;
    end else begin
      if (ren_i) begin
        data_q2 <= $signed(ram[rd_addr2_i]);
      end
    end
  end

  // Output assignment
  assign data_o1 = $signed(data_q1);
  assign data_o2 = $signed(data_q2);

endmodule : samples_ram_2mult

