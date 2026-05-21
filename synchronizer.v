// =============================================================================
// TWO-FLOP SYNCHRONIZER
// Passes a Gray-code pointer safely across a clock domain boundary.
// Only 1 bit changes per cycle in Gray code, so metastability risk is minimal.
//
// Parameter:
//   WIDTH : pointer bus width = PTR_WIDTH+1
// =============================================================================
`timescale 1ns/1ps   
module synchronizer #(
  parameter WIDTH = 5          // default matches PTR_WIDTH+1 for DEPTH=16
) (
  input  wire             clk,
  input  wire             rst_n,
  input  wire [WIDTH-1:0] d_in,
  output reg  [WIDTH-1:0] d_out
);

  reg [WIDTH-1:0] stage1;      // first  flop - captures metastable input
                               // second flop (d_out) - stable output

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage1 <= {WIDTH{1'b0}};
      d_out  <= {WIDTH{1'b0}};
    end else begin
      stage1 <= d_in;          // STAGE 1: sample 
      d_out  <= stage1;        // STAGE 2: resolved, safe to use
    end
  end

endmodule