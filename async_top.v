`timescale 1ns/1ps 
module async_top #(
  parameter DEPTH      = 16,
  parameter DATA_WIDTH = 8
) (
  // Write clock domain
  input  wire                  wclk,
  input  wire                  wrst_n,
  input  wire                  w_en,
  input  wire [DATA_WIDTH-1:0] data_in,
  output wire                  full,

  // Read clock domain
  input  wire                  rclk,
  input  wire                  rrst_n,
  input  wire                  r_en,
  output wire [DATA_WIDTH-1:0] data_out,
  output wire                  empty
);


  localparam PTR_WIDTH = $clog2(DEPTH);   // DEPTH=16 -> PTR_WIDTH=4
  wire [PTR_WIDTH:0] b_wptr;
  wire [PTR_WIDTH:0] b_rptr;

  // Gray-code pointers 
  wire [PTR_WIDTH:0] g_wptr;
  wire [PTR_WIDTH:0] g_rptr;

  // Gray-code pointers (after CDC synchronization to opposite domain)
  wire [PTR_WIDTH:0] g_wptr_sync;   // g_wptr crossed into read  domain
  wire [PTR_WIDTH:0] g_rptr_sync;   // g_rptr crossed into write domain

  // --------------------------------------------------------------------------
  // CDC: 2-flop synchronizers
  // g_wptr  ->  read  domain  (used by rptr_handler for empty check)
  // g_rptr  ->  write domain  (used by wptr_handler for full  check)
  // --------------------------------------------------------------------------
  synchronizer #(.WIDTH(PTR_WIDTH+1)) sync_wptr (
    .clk   (rclk),
    .rst_n (rrst_n),
    .d_in  (g_wptr),
    .d_out (g_wptr_sync)
  );

  synchronizer #(.WIDTH(PTR_WIDTH+1)) sync_rptr (
    .clk   (wclk),
    .rst_n (wrst_n),
    .d_in  (g_rptr),
    .d_out (g_rptr_sync)
  );

  // Write pointer handler - runs in write clock domain
  wptr_handler #(.PTR_WIDTH(PTR_WIDTH)) wptr_h (
    .wclk        (wclk),
    .wrst_n      (wrst_n),
    .w_en        (w_en),
    .g_rptr_sync (g_rptr_sync),
    .b_wptr      (b_wptr),
    .g_wptr      (g_wptr),
    .full        (full)
  );
  
  // Read pointer handler - runs in read clock domain
  rptr_handler #(.PTR_WIDTH(PTR_WIDTH)) rptr_h (
    .rclk        (rclk),
    .rrst_n      (rrst_n),
    .r_en        (r_en),
    .g_wptr_sync (g_wptr_sync),
    .b_rptr      (b_rptr),
    .g_rptr      (g_rptr),
    .empty       (empty)
  );

  // FIFO memory - dual port, sync write / async read

  fifo_mem #(
    .DEPTH      (DEPTH),
    .DATA_WIDTH (DATA_WIDTH),
    .PTR_WIDTH  (PTR_WIDTH)
  ) mem (
    .wclk     (wclk),
    .w_en     (w_en),
    .b_wptr   (b_wptr),
    .data_in  (data_in),
    .full     (full),
    .b_rptr   (b_rptr),
    .empty    (empty),
    .data_out (data_out)
  );

endmodule