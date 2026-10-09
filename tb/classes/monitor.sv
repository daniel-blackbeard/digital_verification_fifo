class monitor;

    virtual fifo_if vif;
    mailbox #(result) mon_scr;

    function new(virtual fifo_if v, mailbox #(result) ms);
        this.vif     = v;
        this.mon_scr = ms;
    endfunction

    task run();
        result rx;
        forever begin
            @(posedge vif.clk);
            rx = new();
            rx.empty        = vif.empty;
            rx.full         = vif.full;
            rx.rd_data      = vif.rd_data;
            rx.almost_full  = vif.almost_full;
            rx.almost_empty = vif.almost_empty;
            rx.count        = vif.count;

            mon_scr.put(rx);
        end
        
    endtask

endclass
