class monitor#(int DEPTH=16);

    covergroup cg_fifo_ops with function sample(
        transaction #()::t_op_type f_op, 
        logic [$clog2(DEPTH):0]    f_count, 
        logic [3:0]                f_status
    );

        cp_op: coverpoint f_op {
            bins read_only  = {transaction #()::READ};
            bins write_only = {transaction #()::WRITE};
            bins sim_rw     = {transaction #()::BOTH};
            bins idle       = {transaction #()::IDLE};
        }

        cp_fill_level: coverpoint f_count {
            bins fifo_empty    = {0};
            bins fifo_partial  = {[1:15]};
            bins fifo_full     = {16};
        }

        cp_status_flags: coverpoint f_status {
            bins empty        = {4'b1010};
            bins full         = {4'b0101};
            bins almost_empty = {4'b0010};
            bins almost_full  = {4'b0001};
            bins no_status    = {4'b0000};
        }

        cr_op_vs_fill: cross cp_op, cp_fill_level;
        cr_op_vs_stat: cross cp_op, cp_status_flags;

    endgroup

    virtual fifo_if vif;
    mailbox #(result)      mon_scr;
    mailbox #(transaction) mon_ref;
    int th_empty;
    int th_full;
    
    function new(virtual fifo_if v, mailbox #(result) ms, mailbox #(transaction) mr);
        this.vif     = v;
        this.mon_scr = ms;
        this.mon_ref = mr;
        cg_fifo_ops = new();
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
            
            tx.op           = transaction #()::t_op_type'({vif.cbm.wr_en, vif.cbm.rd_en});
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

            cg_fifo_ops.sample(
                tx.op, 
                rx.count, 
                {rx.empty, rx.full, rx.almost_empty, rx.almost_full});
        end
    endtask

endclass
