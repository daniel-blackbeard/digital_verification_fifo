class monitor;

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        READ  = 2'b01,
        WRITE = 2'b10,
        BOTH  = 2'b11
    } t_op_type;

    virtual fifo_if vif;
    mailbox #(result)      mon_scr;
    mailbox #(transaction) mon_ref;
    int th_empty;
    int th_full;
    
    function new(virtual fifo_if v, mailbox #(result) ms, mailbox #(transaction) mr);
        this.vif     = v;
        this.mon_scr = ms;
        this.mon_ref = mr;
    endfunction

    task run();
        result      rx;
        transaction tx, tx_prev;
        tx_prev = null;

        forever begin
            @(vif.cb);
            rx = new();
            tx = new();

            rx.empty        = vif.cb.empty;
            rx.full         = vif.cb.full;
            rx.rd_data      = vif.cb.rd_data;
            rx.almost_full  = vif.cb.almost_full;
            rx.almost_empty = vif.cb.almost_empty;
            rx.count        = vif.cb.count;
            
            tx.op           = t_op_type'({vif.cbm.wr_en, vif.cbm.rd_en});
            tx.wr_data      = vif.cbm.wr_data;
            tx.th_empty     = vif.cbm.almost_empty_tresh;   
            tx.th_full      = vif.cbm.almost_full_tresh;
            

            th_empty     = $bits(th_empty)'(tx.th_empty);
            th_full      = $bits(th_full)'(tx.th_full);

            if (tx_prev != null) begin 
                tx_prev.th_empty     = $bits(tx.th_empty)'(th_empty);
                tx_prev.th_full      = $bits(tx.th_full)'(th_full);
                mon_ref.put(tx_prev);
                mon_scr.put(rx);
            end
            tx_prev = tx;
            
        end
        
    endtask

endclass
