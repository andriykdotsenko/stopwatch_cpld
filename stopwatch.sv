module synch (
  input  logic clk,
  input  logic d,
  output logic q
);
  logic meta;

  always_ff @(posedge clk) begin
    meta <= d;
    q <= meta;
  end
endmodule

module debounce (
  input  logic clk,
  input  logic rst,
  input  logic d,
  output logic q
);
  logic [18:0] counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      q <= 0;
      counter <= 0;
    end else if (d == q) begin
      counter <= 0;
    end else if (counter == 499_999) begin
      q <= d;
      counter <= 0;
    end else begin
      counter <= counter + 1;
    end
  end
endmodule


module edge_detector (
  input  logic clk,
  input  logic rst,
  input  logic btn_in,
  output logic pulse_out
);
  logic btn_prev;

  always_ff @(posedge clk) begin
    if (rst) 
	 btn_prev <= 0;
    else     
	 btn_prev <= btn_in;
  end

  assign pulse_out = (btn_in == 1) & (btn_prev == 0);
endmodule


module clk_div (
  input  logic clk,
  input  logic rst,
  output logic tick_1s
);
  logic [25:0] counter;

  assign tick_1s = (counter == 49_999_999);

  always_ff @(posedge clk) begin
    if (rst || counter == 49_999_999) 
	 counter <= 0;
    else                              
	 counter <= counter + 1;
  end
endmodule


module seg7_decoder (
  input  logic [3:0] a,
  output logic [6:0] y
);
  logic [6:0] seg_on;

  always_comb begin
    case (a)
      4'd0:    seg_on = 7'b0111111;
      4'd1:    seg_on = 7'b0000110;
      4'd2:    seg_on = 7'b1011011;
      4'd3:    seg_on = 7'b1001111;
      4'd4:    seg_on = 7'b1100110;
      4'd5:    seg_on = 7'b1101101;
      4'd6:    seg_on = 7'b1111101;
      4'd7:    seg_on = 7'b0000111;
      4'd8:    seg_on = 7'b1111111;
      4'd9:    seg_on = 7'b1101111;
      default: seg_on = 7'b0000000;
    endcase
  end

  assign y = ~seg_on;
endmodule


module bcd_digit #(
  parameter logic [3:0] MAX = 9
) (
  input  logic clk,
  input  logic rst,
  input  logic en,
  input  logic up,
  output logic [3:0] digit,
  output logic wrap
);
  always_ff @(posedge clk) begin
    if (rst) begin
      digit <= 0;
    end else if (en) begin
      if (up) begin
        if (digit == MAX) 
		  digit <= 0;
        else              
		  digit <= digit + 1;
      end else begin
        if (digit == 0)   
		  digit <= MAX;
        else              
		  digit <= digit - 1;
      end
    end
  end

  assign wrap = en && (up ? (digit == MAX) : (digit == 0));
endmodule


module stopwatch_ctrl (
  input  logic clk,
  input  logic rst,
  input  logic tick_1s,
  input  logic start_stop_pulse,
  input  logic dir_pulse,
  input  logic lap_reset_pulse,
  output logic count_en,      
  output logic count_up,      
  output logic lap_hold,      
  output logic counter_rst    
);
  logic running;

  always_ff @(posedge clk) begin
    if (rst) begin
      running  <= 0;
      count_up <= 1;
      lap_hold <= 0;
    end else begin
      if (start_stop_pulse) 
		running  <= ~running;
      if (dir_pulse)        
		count_up <= ~count_up;

      if (lap_reset_pulse) begin
        if (running) 
		  lap_hold <= ~lap_hold;   
        else         
		  lap_hold <= 0;           
      end
    end
  end

  assign count_en = tick_1s && running;
  assign counter_rst = lap_reset_pulse && !running;
endmodule



module stopwatch (
  input  logic clk,
  input  logic btn_start,   
  input  logic btn_dir,     
  input  logic btn_lap,     
  output logic [6:0] seg_tens,
  output logic [6:0] seg_ones
);

  logic [3:0] por_cnt = 4'd0;
  logic rst;

  always_ff @(posedge clk) begin
    if (por_cnt != 4'hF) 
	 por_cnt <= por_cnt + 1;
  end
  assign rst = (por_cnt != 4'hF);

  logic start_sync, start_clean, start_pulse;
  
  synch u_start_sync (
  .clk(clk),
  .d(~btn_start),
  .q(start_sync)
  );
  
  debounce u_start_deb  (
  .clk(clk),
  .rst(rst),
  .d(start_sync),
  .q(start_clean)
  );
  
  edge_detector u_start_edge (
  .clk(clk),
  .rst(rst),
  .btn_in(start_clean),
  .pulse_out(start_pulse)
  );

  logic dir_sync, dir_clean, dir_pulse;
  
  synch u_dir_sync (
  .clk(clk),
  .d(~btn_dir),
  .q(dir_sync)
  );
  
  debounce u_dir_deb  (
  .clk(clk),
  .rst(rst),
  .d(dir_sync),
  .q(dir_clean)
  );
  
  edge_detector u_dir_edge (
  .clk(clk),
  .rst(rst),
  .btn_in(dir_clean),
  .pulse_out(dir_pulse)
  );

  logic lap_sync, lap_clean, lap_pulse;
  
  synch u_lap_sync (
  .clk(clk),
  .d(~btn_lap),
  .q(lap_sync)
  );
  
  debounce u_lap_deb  (
  .clk(clk),
  .rst(rst),
  .d(lap_sync),
  .q(lap_clean)
  );
  
  edge_detector u_lap_edge (
  .clk(clk),
  .rst(rst),
  .btn_in(lap_clean),
  .pulse_out(lap_pulse)
  );

  logic tick_1s;
  clk_div u_div (
  .clk(clk),
  .rst(rst),
  .tick_1s(tick_1s)
  );

  logic count_en, count_up, lap_hold, counter_rst;
  
  stopwatch_ctrl u_ctrl (
    .clk (clk),
    .rst (rst),
    .tick_1s (tick_1s),
    .start_stop_pulse (start_pulse),
    .dir_pulse (dir_pulse),
    .lap_reset_pulse (lap_pulse),
    .count_en (count_en),
    .count_up (count_up),
    .lap_hold (lap_hold),
    .counter_rst (counter_rst)
  );

  logic [3:0] ones, tens;
  logic wrap_ones;
  logic cnt_rst;
  assign cnt_rst = rst || counter_rst;

  bcd_digit #(.MAX(9)) u_ones (
    .clk(clk),
	 .rst(cnt_rst),
	 .en(count_en),
	 .up(count_up),
    .digit(ones),
	 .wrap(wrap_ones)
  );

  bcd_digit #(.MAX(5)) u_tens (
    .clk(clk),
	 .rst(cnt_rst),
	 .en(wrap_ones),
	 .up(count_up),
    .digit(tens),
	 .wrap()
  );

  logic [3:0] lap_ones, lap_tens;

  always_ff @(posedge clk) begin
    if (rst) begin
      lap_ones <= 0;
      lap_tens <= 0;
    end else if (!lap_hold) begin
      lap_ones <= ones;
      lap_tens <= tens;
    end
  end

  logic [3:0] disp_ones, disp_tens;
  assign disp_ones = lap_hold ? lap_ones : ones;
  assign disp_tens = lap_hold ? lap_tens : tens;

  seg7_decoder u_seg_ones (
  .a(disp_ones),
  .y(seg_ones)
  );
  
  seg7_decoder u_seg_tens (
  .a(disp_tens),
  .y(seg_tens)
  );

endmodule
