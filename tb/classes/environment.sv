class environment;

  generator          gen;
  driver             drv;
  monitor            mon;
  fifo_sync_prog_ref ref_mod;
  scoreboard         scb;
  

  mailbox #(transaction) gen_drv, gen_ref;
  mailbox #(result) mon_scb, ref_scb;

  function new(virtual fifo_if vif);
    gen_drv = new();
    gen_ref = new();
    mon_scb = new();
    ref_scb = new();

    gen     = new(gen_drv, gen_ref);
    drv     = new(vif, gen_drv);
    mon     = new(vif, mon_scb);
    ref_mod = new(gen_ref, ref_scb);
    scb     = new(mon_scb, ref_scb);
  endfunction

  task run(int test_length);
    fork
      drv.run();
      mon.run();
      ref_mod.run();
      scb.run();
    join_none

    gen.run(test_length);
    
    #100; 
  endtask
endclass
