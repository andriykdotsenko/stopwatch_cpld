stopwatch_cpld
Up/down stopwatch with lap in SystemVerilog for Altera MAX II (EPM570) CPLD


Verification

Self-checking testbenches (Icarus Verilog 12, EDA Playground), both print `ALL TESTS PASSED`:

- `testbench/tb_stopwatch_ctrl.sv` – control FSM: Start/Stop, direction, Lap/Reset, reset behavior
- `testbench/tb_bcd_digit.sv` – two chained BCD digits (0..59) compared with a reference model, up and down, wrap flags

![bcd_digit waveform](testbench/bcd_digit_waveform.png)

The ones digit wraps 9 → 0 and `wrap_ones` increments the tens digit.
