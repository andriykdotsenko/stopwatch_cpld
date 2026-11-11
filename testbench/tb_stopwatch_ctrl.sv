`timescale 1ns/1ps

module tb_stopwatch_ctrl;

  logic clk = 0;
  logic rst, tick_1s;
  logic start_stop_pulse, dir_pulse, lap_reset_pulse;
  logic count_en, count_up, lap_hold, counter_rst;

  int errors = 0;

  stopwatch_ctrl dut (
    .clk(clk),
    .rst(rst),
    .tick_1s(tick_1s),
    .start_stop_pulse(start_stop_pulse),
    .dir_pulse(dir_pulse),
    .lap_reset_pulse(lap_reset_pulse),
    .count_en(count_en),
    .count_up(count_up),
    .lap_hold(lap_hold),
    .counter_rst(counter_rst)
  );

  always #10 clk = ~clk;

  task automatic pulse_start();
    @(negedge clk); start_stop_pulse = 1;
    @(negedge clk); start_stop_pulse = 0;
  endtask

  task automatic pulse_dir();
    @(negedge clk); dir_pulse = 1;
    @(negedge clk); dir_pulse = 0;
  endtask

  task automatic pulse_lap();
    @(negedge clk); lap_reset_pulse = 1;
    @(negedge clk); lap_reset_pulse = 0;
  endtask

  task automatic check(input string name, input logic cond);
    if (cond) $display("PASS: %s", name);
    else begin
      $display("FAIL: %s", name);
      errors++;
    end
  endtask

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_stopwatch_ctrl);

    rst = 1;
    tick_1s = 0;
    start_stop_pulse = 0;
    dir_pulse = 0;
    lap_reset_pulse = 0;
    repeat (3) @(negedge clk);
    rst = 0;
    @(negedge clk);

    check("after reset: count_up = 1", count_up);
    check("after reset: lap_hold = 0", !lap_hold);
    tick_1s = 1; #1;
    check("stopped: tick gives no count_en", !count_en);
    tick_1s = 0;

    pulse_start();
    tick_1s = 1; #1;
    check("running: tick gives count_en", count_en);
    tick_1s = 0; #1;
    check("running: no tick, no count_en", !count_en);

    pulse_start();
    tick_1s = 1; #1;
    check("stopped again: no count_en", !count_en);
    tick_1s = 0;

    pulse_dir();
    check("dir pulse: count_up = 0", !count_up);
    pulse_dir();
    check("dir pulse again: count_up = 1", count_up);

    pulse_start();
    pulse_lap();
    check("lap while running: hold = 1", lap_hold);
    pulse_lap();
    check("lap again: hold = 0", !lap_hold);

    @(negedge clk); lap_reset_pulse = 1; #1;
    check("running: no counter_rst", !counter_rst);
    @(negedge clk); lap_reset_pulse = 0;

    pulse_start();
    check("stop keeps hold = 1", lap_hold);
    @(negedge clk); lap_reset_pulse = 1; #1;
    check("stopped: counter_rst pulse", counter_rst);
    @(negedge clk); lap_reset_pulse = 0;
    check("reset while stopped: hold = 0", !lap_hold);
    #1;
    check("no pulse: no counter_rst", !counter_rst);


    pulse_start();
    pulse_dir();       
    @(negedge clk); rst = 1;
    @(negedge clk); rst = 0;
    check("rst: count_up back to 1", count_up);
    check("rst: lap_hold = 0", !lap_hold);
    tick_1s = 1; #1;
    check("rst: stopped, no count_en", !count_en);
    tick_1s = 0;

    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end

endmodule
