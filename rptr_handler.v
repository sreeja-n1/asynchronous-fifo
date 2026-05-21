// READ POINTER HANDLER - Runs entirely in the READ clock domain (rclk).
// DATAPATH  - computes and registers the binary and Gray-code read pointers
// CONTROL   - compares Gray pointers to detect EMPTY condition
// Empty condition:
//   The FIFO is empty when the next Gray read pointer equals the synchronized
//   Gray write pointer. Both point to the same location - nothing to read.
//   Checked on the NEXT pointer (before registering) so empty deasserts on
//   the same cycle a new word becomes visible.
// Parameter:
//   PTR_WIDTH : number of address bits = $clog2(DEPTH)
//               pointer bus is PTR_WIDTH+1 bits (extra MSB = wrap-around bit)
// =============================================================================
`timescale 1ns/1ps  
module rptr_handler #(
  parameter PTR_WIDTH = 4             
) (
  input  wire                 rclk,
  input  wire                 rrst_n,
  input  wire                 r_en,
  input  wire [PTR_WIDTH:0]   g_wptr_sync,  

  // Datapath outputs
  output reg  [PTR_WIDTH:0]   b_rptr,      
  output reg  [PTR_WIDTH:0]   g_rptr,      

  output reg                  empty
);

  // DATAPATH - next-state logic (combinational)
  
  wire [PTR_WIDTH:0] b_rptr_next;
  wire [PTR_WIDTH:0] g_rptr_next;

  // Increment binary pointer only when reading and not empty
  assign b_rptr_next = b_rptr + (r_en & ~empty);

  // Convert binary to Gray
  assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;

  // DATAPATH - pointer registers (read clock domain)
  
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      b_rptr <= {(PTR_WIDTH+1){1'b0}};
      g_rptr <= {(PTR_WIDTH+1){1'b0}};
    end else begin
      b_rptr <= b_rptr_next;
      g_rptr <= g_rptr_next;
    end
  end

  // CONTROL - empty flag logic (combinational detect, registered output)
  // Empty when next Gray read pointer == synchronized Gray write pointer
  wire rempty;
  assign rempty = (g_wptr_sync == g_rptr_next);

  // Register the empty flag (resets to 1 - FIFO starts empty)
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) empty <= 1'b1;
    else         empty <= rempty;
  end

endmodule