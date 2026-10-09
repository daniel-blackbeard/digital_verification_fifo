class driver;

    virtual fifo_if vif;
    mailbox #(transaction) gen_drv;

    function new(virtual fifo_if v, mailbox #(transaction) gd);
        this.vif = v;
        this.gen_drv = gd;
    endfunction

    task run();
        transaction tx;
        forever begin
            gen_drv.get(tx);

            @(posedge vif.clk);
            vif.rd_en   = tx.op[0];
            vif.wr_en   = tx.op[1];
            vif.wr_data = tx.wr_data;
            vif.almost_empty_tresh = tx.th_empty;
            vif.almost_full_tresh  = tx.th_full;
        end
    endtask
endclass
