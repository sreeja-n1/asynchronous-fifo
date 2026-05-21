`timescale 1ns/1ps
module async_fifo_tb;

  parameter DATA_WIDTH = 8;
  parameter DEPTH      = 16;
  parameter MAX_TRANS  = 64;

  wire [DATA_WIDTH-1:0] data_out;
  wire                  full;
  wire                  empty;

  reg  [DATA_WIDTH-1:0] data_in;
  reg                   w_en,  wclk,  wrst_n;
  reg                   r_en,  rclk,  rrst_n;

  reg [DATA_WIDTH-1:0] ref_mem [0:MAX_TRANS-1];
  
  integer ref_wr_ptr;
  integer ref_rd_ptr;
  integer pass_count;
  integer fail_count;
  integer i;
  integer round;

  // DUT
  async_top #(
    .DEPTH      (DEPTH),
    .DATA_WIDTH (DATA_WIDTH)
  ) dut (
    .wclk     (wclk),
    .wrst_n   (wrst_n),
    .w_en     (w_en),
    .data_in  (data_in),
    .full     (full),
    .rclk     (rclk),
    .rrst_n   (rrst_n),
    .r_en     (r_en),
    .data_out (data_out),
    .empty    (empty)
  );

  initial wclk = 1'b0;
  always  #10 wclk = ~wclk;

  initial rclk = 1'b0;
  always  #35 rclk = ~rclk;

  initial begin
    wrst_n     = 1'b0;
    w_en       = 1'b0;
    data_in    = {DATA_WIDTH{1'b0}};
    ref_wr_ptr = 0;

    repeat(10) @(posedge wclk);
    wrst_n = 1'b1;
    @(posedge wclk);

    for (round = 0; round < 2; round = round + 1) begin
      for (i = 0; i < 30; i = i + 1) begin
        @(posedge wclk);
        while (full) @(posedge wclk);

        if (i % 2 == 0) begin
          w_en    = 1'b1;
          data_in = $random & 8'hFF;
          ref_mem[ref_wr_ptr % MAX_TRANS] = data_in;
          ref_wr_ptr = ref_wr_ptr + 1;
        end else begin
          w_en = 1'b0;
        end
      end
      w_en = 1'b0;
      #100;
    end
  end

  initial begin
    rrst_n     = 1'b0;
    r_en       = 1'b0;
    ref_rd_ptr = 0;
    pass_count = 0;
    fail_count = 0;

    repeat(20) @(posedge rclk);
    rrst_n = 1'b1;
    @(posedge rclk);

    for (round = 0; round < 2; round = round + 1) begin
      for (i = 0; i < 30; i = i + 1) begin

        @(posedge rclk);
        while (empty) @(posedge rclk);

        if (i % 2 == 0) begin
          r_en = 1'b1;
          @(posedge rclk);
          r_en = 1'b0;

          if (data_out !== ref_mem[ref_rd_ptr % MAX_TRANS]) begin
            $display("FAIL | Time=%0t | expected=0x%02h | got=0x%02h",
                     $time,
                     ref_mem[ref_rd_ptr % MAX_TRANS],
                     data_out);
            fail_count = fail_count + 1;
          end else begin
            $display("PASS | Time=%0t | data=0x%02h", $time, data_out);
            pass_count = pass_count + 1;
          end
          ref_rd_ptr = ref_rd_ptr + 1;
        end
      end
      r_en = 1'b0;
      #100;
    end

    $display("--------------------------------------------");
    $display("Simulation complete: %0d PASS  /  %0d FAIL", pass_count, fail_count);
    $display("--------------------------------------------");
    $finish;
  end

  // Waveform dump
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, async_fifo_tb);
  end

endmodule