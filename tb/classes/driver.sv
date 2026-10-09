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

            @(vif.cb);
            vif.cb.rd_en   <= tx.op[0];
            vif.cb.wr_en   <= tx.op[1];
            vif.cb.wr_data <= tx.wr_data;
            vif.cb.almost_empty_tresh <= tx.th_empty;
            vif.cb.almost_full_tresh  <= tx.th_full;
        end
    endtask
endclass
