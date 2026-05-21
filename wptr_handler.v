// WRITE POINTER HANDLER - Runs entirely in the WRITE clock domain (wclk).
// DATAPATH  - computes and registers the binary and Gray-code write pointers
// CONTROL   - compares Gray pointers to detect FULL condition
// Full condition (Cummings, SNUG 2002):
//   The write pointer has lapped the read pointer when the next Gray write
//   pointer matches the synchronized Gray read pointer with its top 2 MSBs
//   inverted. This works because Gray code wraps with a 2-bit inversion at
//   the MSBs when the pointer crosses the halfway point of the address space.
// Parameter:
//   PTR_WIDTH : number of address bits = $clog2(DEPTH)
//               pointer bus is PTR_WIDTH+1 bits (extra MSB = wrap-around bit)
// =============================================================================
`timescale 1ns/1ps  
module wptr_handler #(
  parameter PTR_WIDTH = 4              
) (
  input  wire                 wclk,
  input  wire                 wrst_n,
  input  wire                 w_en,
  input  wire [PTR_WIDTH:0]   g_rptr_sync,  

  // Datapath outputs
  output reg  [PTR_WIDTH:0]   b_wptr,       
  output reg  [PTR_WIDTH:0]   g_wptr,       

  // Control output
  output reg                  full
);

  // DATAPATH - next-state logic (combinational)
  
  wire [PTR_WIDTH:0] b_wptr_next;
  wire [PTR_WIDTH:0] g_wptr_next;

  // Increment binary pointer only when writing and not full
  assign b_wptr_next = b_wptr + (w_en & ~full);

  // Convert binary to Gray
  assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next;

  // DATAPATH - pointer registers (write clock domain)
  
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      b_wptr <= {(PTR_WIDTH+1){1'b0}};
      g_wptr <= {(PTR_WIDTH+1){1'b0}};
    end else begin
      b_wptr <= b_wptr_next;
      g_wptr <= g_wptr_next;
    end
  end

  // CONTROL - full flag logic (combinational detect, registered output)
 
  wire wfull;
  assign wfull = (g_wptr_next == {~g_rptr_sync[PTR_WIDTH:PTR_WIDTH-1],
                                    g_rptr_sync[PTR_WIDTH-2:0]});

  // Register the full flag (resets to 0 - FIFO starts not full)
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) full <= 1'b0;
    else         full <= wfull;
  end

endmodule