class environment;

  generator          gen;
  driver             drv;
  monitor            mon;
  fifo_sync_prog_ref ref_mod;
  scoreboard         scb;
  virtual fifo_if    vif;

  mailbox #(transaction) gen_drv, mon_ref;
  mailbox #(result) mon_scb, ref_scb;

  function new(virtual fifo_if v);
    gen_drv  = new();
    mon_scb  = new();
    mon_ref  = new();
    ref_scb  = new();
    this.vif = v;

    gen     = new(gen_drv);
    drv     = new(vif, gen_drv);
    mon     = new(vif, mon_scb, mon_ref);
    ref_mod = new(mon_ref, ref_scb);
    scb     = new(mon_scb, ref_scb);
  endfunction

  task setup();
    fork
      drv.run();
      mon.run();
      ref_mod.run();
      scb.run();
    join_none
  endtask

  task wait_until_done();
    while (gen_drv.num() > 0) @(vif.cb);
    repeat (5) @(vif.cb);
  endtask

  task report_results();
    $display("Simulation completed, %0d passes and %0d failures from OOSV", scb.pass, scb.fail);
    if(scb.fail == '0) $display("PASS\n"); else $display("FAIL\n");
    $finish();
  endtask
endclass
