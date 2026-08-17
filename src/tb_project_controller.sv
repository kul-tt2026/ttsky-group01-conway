`default_nettype none
`timescale 1ns / 1ps

module tb_project_controller ();

  localparam int CLK_PERIOD = 10;  // ns

  logic clk, reset_n, next_iter, start_stop_rise, L_idle;
  logic L_reset, nic_reset, reset_speed, running, next_iter_busy;

  int errors = 0;

  project_controller dut (
      .clk(clk),
      .reset_n(reset_n),
      .next_iter(next_iter),
      .L_idle(L_idle),
      .start_stop_rise(start_stop_rise),
      .L_reset(L_reset),
      .nic_reset(nic_reset),
      .reset_speed(reset_speed),
      .running(running),
      .next_iter_busy(next_iter_busy)
  );

  // Klok
  initial clk = 1'b0;
  always #(CLK_PERIOD / 2) clk = ~clk;

  // Waveform
  initial begin
    $dumpfile("tb_project_controller.vcd");
    $dumpvars(0, tb_project_controller);
  end

  // Watchdog
  initial begin
    #(CLK_PERIOD * 500);
    $error("TIMEOUT: testbench is niet klaargeraakt");
    $fatal(1, "TIMEOUT: testbench is niet klaargeraakt");
  end

  // Hulpfuncties
  task automatic step(input int n = 1);
    repeat (n) @(negedge clk);
  endtask

  task automatic check(input bit cond, input string msg);
    if (!cond) begin
      errors++;
      $error("[%0t] %s", $time, msg);
    end
  endtask

  // Pulse start_stop_rise for exactly one cycle, mirroring what a real
  // edge-detected button press looks like from Input.sv.
  task automatic pulse_start_stop();
    start_stop_rise = 1'b1;
    step(1);
    start_stop_rise = 1'b0;
  endtask

  // Tests
  initial begin

    reset_n = '0;
    start_stop_rise = '0;
    next_iter = '0;
    L_idle = '0;

    // Test 1: next state logica

    step(1);
    reset_n = 1'b1;

    check(dut.state === dut.START, "reset_n werkt niet");

    step(2);
    check(dut.state === dut.START, "state advanced terwijl dat niet mag (1)");

    pulse_start_stop();
    step(2);
    check(dut.state === dut.DISPLAY, "advanced niet naar DISPLAY (1)");

    next_iter = 1'b1;
    step(2);
    check(dut.state === dut.NEXT_ITER, "advanced niet naar NEXT_ITER");
    next_iter = 1'b0;

    L_idle = 1'b1;
    step(1);
    check(dut.state === dut.DISPLAY, "advanced niet naar DISPLAY (2)");
    L_idle = 1'b0;

    // Test 1b: pause/resume is nu ontkoppeld van next_iter, moet dus
    // altijd werken zodra start_stop_rise pulseert, ongeacht next_iter.
    pulse_start_stop();
    step(2);
    check(dut.state === dut.PAUSE, "advanced niet naar PAUSE bij start_stop_rise alleen");

    // Terwijl gepauzeerd: next_iter mag geen effect hebben, alleen
    // start_stop_rise mag terug naar DISPLAY gaan.
    next_iter = 1'b1;
    step(2);
    check(dut.state === dut.PAUSE, "PAUSE mag niet verlaten worden door next_iter alleen");
    next_iter = 1'b0;

    pulse_start_stop();
    step(2);
    check(dut.state === dut.DISPLAY, "advanced niet terug naar DISPLAY vanuit PAUSE");

    // Test 1c: pause/resume moet ook werken wanneer next_iter toevallig
    // op dezelfde cyclus samenvalt met start_stop_rise (regressietest voor
    // de oude bug waar dit een AND-voorwaarde was).
    next_iter = 1'b1;
    start_stop_rise = 1'b1;
    step(1);
    start_stop_rise = 1'b0;
    next_iter = 1'b0;
    step(2);
    check(dut.state === dut.PAUSE,
          "PAUSE moet bereikt worden zelfs als next_iter samenvalt met start_stop_rise");

    pulse_start_stop();
    step(2);
    check(dut.state === dut.DISPLAY, "resume vanuit PAUSE faalt na samenvallende next_iter+start_stop_rise");

    reset_n = '0;
    step(1);
    reset_n = 1'b1;

    // Test 2: controlesignalen

    // START
    check(dut.state === dut.START, "check_controlesignalen START gebeurt op andere state");
    check(
        L_reset === 1'b1 && nic_reset === 1'b1 && reset_speed === 1'b1 &&
              running === 1'b0 && next_iter_busy === 1'b0,
        "controlesignalen START zijn fout");

    pulse_start_stop();
    step(1);

    // DISPLAY
    check(dut.state === dut.DISPLAY, "check_controlesignalen DISPLAY gebeurt op andere state");
    check(
        L_reset === 1'b0 && nic_reset === 1'b0 && reset_speed === 1'b0 &&
              running === 1'b1 && next_iter_busy === 1'b0,
        "controlesignalen DISPLAY zijn fout");

    next_iter = 1'b1;
    step(1);
    next_iter = 1'b0;

    // NEXT_ITER
    check(dut.state === dut.NEXT_ITER, "check_controlesignalen NEXT_ITER gebeurt op andere state");
    check(
        L_reset === 1'b0 && nic_reset === 1'b0 && reset_speed === 1'b0 &&
              running === 1'b1 && next_iter_busy === 1'b1,
        "controlesignalen NEXT_ITER zijn fout");

    L_idle = 1'b1;
    step(1);
    L_idle = 1'b0;
    check(dut.state === dut.DISPLAY, "terug naar DISPLAY na NEXT_ITER faalt");

    pulse_start_stop();
    step(1);

    // PAUSE
    check(dut.state === dut.PAUSE, "check_controlesignalen PAUSE gebeurt op andere state");
    check(
        L_reset === 1'b1 && nic_reset === 1'b1 && reset_speed === 1'b0 &&
              running === 1'b0 && next_iter_busy === 1'b0,
        "controlesignalen PAUSE zijn fout");

    // Bug-regressietest: nic_reset moet in PAUSE hoog zijn (blokkeert de
    // countdown), maar dat mag PAUSE->DISPLAY niet meer blokkeren zoals
    // in de oude implementatie waar dit een deadlock veroorzaakte.
    pulse_start_stop();
    step(1);
    check(dut.state === dut.DISPLAY,
          "PAUSE->DISPLAY deadlock: resume faalt terwijl nic_reset countdown blokkeerde");

    // Einde
    if (errors == 0) begin
      $display("=== PASS ===");
      $finish;
    end else begin
      $fatal(1, "=== FAIL: %0d fout(en) ===", errors);
    end
  end

endmodule
