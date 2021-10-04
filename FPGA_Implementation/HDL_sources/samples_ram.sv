/// Description: RAM module for storage of data samples in filter
/// implementation

/// Author: Alkinoos Sarioglou <asarioglou@student.ethz.ch>

module samples_ram #(
    parameter int unsigned DataWidth = 18, // Data Width
    parameter int unsigned AddrWidth = 7   // Address Width
  ) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 ren_i,
    input  logic                 wen_i,
    input  logic [AddrWidth-1:0] rd_addr_i,
    input  logic [AddrWidth-1:0] wr_addr_i,
    input  logic [DataWidth-1:0] data_i,
    output logic [DataWidth-1:0] data_o
  );



  // Specification of RAM memory
  typedef logic [DataWidth-1:0] element;
  element [2**AddrWidth-1:0]    ram;

  logic [DataWidth-1:0]         data_q;

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
  always_ff @(posedge clk_i or negedge rst_ni) begin : proc_data_out
    if(~rst_ni) begin
      data_q <= '0;
    end else begin
      if (ren_i) begin
        data_q <= $signed(ram[rd_addr_i]);
      end
    end
  end

  // Output assignment
  assign data_o = $signed(data_q);

endmodule : samples_ram

