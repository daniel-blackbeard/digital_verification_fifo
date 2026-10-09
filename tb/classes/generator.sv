class generator #(int DEPTH=16);

  mailbox #(transaction) gen_drv;
  mailbox #(transaction) gen_ref;

  function new(mailbox #(transaction) gd, mailbox #(transaction) gr);
    this.gen_drv = gd;
    this.gen_ref = gr;
  endfunction

    task run(int num_transactions);
        transaction tx;
        for (int i = 0; i < num_transactions; i++) begin
            tx = new();
            if (!tx.randomize()) $fatal("Randomization failed!");

            // Send the packet to both the physical driver and the math model
            gen_drv.put(tx); 
            gen_ref.put(tx); 
        end
    endtask

    task fill_fifo();
        transaction tx;
        for(int i = 0; i < DEPTH; i++) begin
            tx = new();

            if (!tx.randomize() with {op == WRITE;}) $fatal("Randomization failed!");

            gen_drv.put(tx); 
            gen_ref.put(tx); 
        end
    endtask

    task empty_fifo();
            transaction tx;
        for(int i = 0; i < DEPTH; i++) begin
            tx = new();

            if (!tx.randomize() with {op == READ;}) $fatal("Randomization failed!");

            gen_drv.put(tx); 
            gen_ref.put(tx); 
        end
    endtask
endclass
