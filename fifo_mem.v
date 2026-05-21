// =============================================================================
// FIFO MEMORY
// Dual-port RAM: synchronous write, asynchronous (combinational) read.

// Parameters:
//   DEPTH      : number of storage locations (must be power of 2)
//   DATA_WIDTH : data bus width in bits
//   PTR_WIDTH  : $clog2(DEPTH) - used to index into the memory array
// =============================================================================
`timescale 1ns/1ps  
module fifo_mem #(
  parameter DEPTH      = 16,
  parameter DATA_WIDTH = 8,
  parameter PTR_WIDTH  = 4       
) (
  // Write port (write clock domain)
  input  wire                  wclk,
  input  wire                  w_en,
  input  wire [PTR_WIDTH:0]    b_wptr,    
  input  wire [DATA_WIDTH-1:0] data_in,
  input  wire                  full,

  // Read port (read clock domain - asynchronous)
  input  wire [PTR_WIDTH:0]    b_rptr,    
  input  wire                  empty,
  output wire [DATA_WIDTH-1:0] data_out
);

  // Memory array: DEPTH locations, each DATA_WIDTH bits wide
  reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  // WRITE - synchronous, gated by w_en and ~full

  always @(posedge wclk) begin
    if (w_en && !full)
      mem[b_wptr[PTR_WIDTH-1:0]] <= data_in;
  end

  // READ - asynchronous (combinational)
  
  assign data_out = mem[b_rptr[PTR_WIDTH-1:0]];

endmodule