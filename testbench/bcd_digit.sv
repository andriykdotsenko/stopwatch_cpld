`timescale 1ns/1ps
 
module tb_bcd_digit;
 
  logic clk = 0;
  logic rst, en, up;
  logic [3:0] ones, tens;
  logic wrap_ones, wrap_tens;
 
  int errors = 0;
  int model  = 0;
 
  bcd_digit #(.MAX(9)) u_ones (
    .clk(clk),
    .rst(rst),
    .en(en),
    .up(up),
    .digit(ones),
    .wrap(wrap_ones)
  );
 
  bcd_digit #(.MAX(5)) u_tens (
    .clk(clk),
    .rst(rst),
    .en(wrap_ones),
    .up(up),
    .digit(tens),
    .wrap(wrap_tens)
  );
 
  always #10 clk = ~clk;
 
  function automatic int val();
    return tens * 10 + ones;
  endfunction
 
  task automatic step();
    @(negedge clk); en = 1;
    @(negedge clk); en = 0;
  endtask
 
  task automatic step_and_check(input string what);
    step();
    if (up) model = (model + 1) % 60;
    else    model = (model + 59) % 60;
    if (val() != model) begin
      $display("FAIL %s: expected %0d, got %0d", what, model, val());
      errors++;
    end
  endtask
 
  task automatic check(input string what, input logic cond);
    if (cond) $display("PASS: %s", what);
    else begin
      $display("FAIL: %s", what);
      errors++;
    end
  endtask
 
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_bcd_digit);
 
    rst = 1; en = 0; up = 1;
    repeat (3) @(negedge clk);
    rst = 0;
    @(negedge clk);
    check("after reset: 00", val() == 0);
 
    up = 1;
    repeat (125) step_and_check("count up");
    $display("count up done, value = %0d", val());
 
    repeat (5) @(negedge clk);
    check("hold when en = 0", val() == model);
 
    up = 0;
    repeat (125) step_and_check("count down");
    $display("count down done, value = %0d", val());
 
    up = 1; repeat (3) step_and_check("switch up");
    up = 0; repeat (3) step_and_check("switch down");
 
    up = 1;
    while (model != 59) step_and_check("go to 59");
    @(negedge clk); en = 1; #1;
    check("wrap on 59 going up (ones and tens)", wrap_ones && wrap_tens);
    en = 0;
    step_and_check("59 -> 00");
    check("59 -> 00 value", val() == 0);
 
    up = 0;
    @(negedge clk); en = 1; #1;
    check("wrap on 00 going down (ones and tens)", wrap_ones && wrap_tens);
    en = 0;
    step_and_check("00 -> 59");
    check("00 -> 59 value", val() == 59);
 
    up = 1;
    while (model != 27) step_and_check("go to 27");
    @(negedge clk); en = 1; #1;
    check("no wrap at 27", !wrap_ones && !wrap_tens);
    en = 0;
 
    @(negedge clk); rst = 1;
    @(negedge clk); rst = 0;
    model = 0;
    check("mid-count reset: 00", val() == 0);
 
    if (errors == 0) $display("ALL TESTS PASSED");
    else             $display("%0d TEST(S) FAILED", errors);
    $finish;
  end
 
endmodule
 
