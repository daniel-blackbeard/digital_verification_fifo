class monitor#(int DEPTH=16);

    localparam logic [1:0] LVL_EMPTY   = 2'b10;
    localparam logic [1:0] LVL_PARTIAL = 2'b00;
    localparam logic [1:0] LVL_FULL    = 2'b01;

    localparam logic [3:0] ST_EMPTY        = 4'b1010;
    localparam logic [3:0] ST_FULL         = 4'b0101;
    localparam logic [3:0] ST_ALMOST_EMPTY = 4'b0010;
    localparam logic [3:0] ST_ALMOST_FULL  = 4'b0001;
    localparam logic [3:0] ST_NONE         = 4'b0000;

    covergroup cg_fifo_ops with function sample(
        transaction #()::t_op_type f_op, 
        logic [$clog2(DEPTH):0]    f_count, 
        logic [3:0]                f_status
    );

        cp_op: coverpoint f_op {
            bins read_only  = {transaction #()::READ};
            bins write_only = {transaction #()::WRITE};
            bins read_write = {transaction #()::BOTH};
            bins idle       = {transaction #()::IDLE};
        }

        cp_fill_level: coverpoint f_count {
            bins fifo_empty    = {0};
            bins fifo_partial  = {[1:15]};
            bins fifo_full     = {16};
        }

        cp_status_flags: coverpoint f_status {
            bins empty        = {ST_EMPTY};
            bins full         = {ST_FULL};
            bins almost_empty = {ST_ALMOST_EMPTY};
            bins almost_full  = {ST_ALMOST_FULL};
            bins no_status    = {ST_NONE};
        }

        cr_op_vs_fill: coverpoint {f_op, f_count == '0, f_count == $bits(f_count)'(DEPTH)} {
            bins idle_x_fifo_empty         = {{transaction #()::IDLE,  LVL_EMPTY}};
            bins idle_x_fifo_partial       = {{transaction #()::IDLE,  LVL_PARTIAL}};
            bins idle_x_fifo_full          = {{transaction #()::IDLE,  LVL_FULL}};
            bins read_only_x_fifo_empty    = {{transaction #()::READ,  LVL_EMPTY}};
            bins read_only_x_fifo_partial  = {{transaction #()::READ,  LVL_PARTIAL}};
            bins write_only_x_fifo_partial = {{transaction #()::WRITE, LVL_PARTIAL}};
            bins write_only_x_fifo_full    = {{transaction #()::WRITE, LVL_FULL}};
            bins read_write_x_fifo_partial = {{transaction #()::BOTH,  LVL_PARTIAL}};

            illegal_bins drop_empty_writes = {{transaction #()::WRITE, LVL_EMPTY}};
            illegal_bins drop_full_reads   = {{transaction #()::READ,  LVL_FULL}};
            illegal_bins drop_empty_rw     = {{transaction #()::BOTH,  LVL_EMPTY}};
            illegal_bins drop_full_rw      = {{transaction #()::BOTH,  LVL_FULL}};
        }

        cr_op_vs_stat: coverpoint {f_op, f_status} {
            bins idle_x_empty              = {{transaction #()::IDLE,  ST_EMPTY}};
            bins idle_x_full               = {{transaction #()::IDLE,  ST_FULL}};
            bins idle_x_almost_empty       = {{transaction #()::IDLE,  ST_ALMOST_EMPTY}};
            bins idle_x_almost_full        = {{transaction #()::IDLE,  ST_ALMOST_FULL}};
            bins idle_x_no_status          = {{transaction #()::IDLE,  ST_NONE}};
            bins read_only_x_empty         = {{transaction #()::READ,  ST_EMPTY}};
            bins read_only_x_almost_empty  = {{transaction #()::READ,  ST_ALMOST_EMPTY}};
            bins read_only_x_almost_full   = {{transaction #()::READ,  ST_ALMOST_FULL}};
            bins read_only_x_no_status     = {{transaction #()::READ,  ST_NONE}};
            bins write_only_x_full         = {{transaction #()::WRITE, ST_FULL}};
            bins write_only_x_almost_empty = {{transaction #()::WRITE, ST_ALMOST_EMPTY}};
            bins write_only_x_almost_full  = {{transaction #()::WRITE, ST_ALMOST_FULL}};
            bins write_only_x_no_status    = {{transaction #()::WRITE, ST_NONE}};
            bins read_write_x_almost_empty = {{transaction #()::BOTH,  ST_ALMOST_EMPTY}};
            bins read_write_x_almost_full  = {{transaction #()::BOTH,  ST_ALMOST_FULL}};
            bins read_write_x_no_status    = {{transaction #()::BOTH,  ST_NONE}};

            illegal_bins drop_empty_writes = {{transaction #()::WRITE, ST_EMPTY}};
            illegal_bins drop_full_reads   = {{transaction #()::READ,  ST_FULL}};
            illegal_bins drop_empty_rw     = {{transaction #()::BOTH,  ST_EMPTY}};
            illegal_bins drop_full_rw      = {{transaction #()::BOTH,  ST_FULL}};
        }

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

                cg_fifo_ops.sample(
                tx_prev.op, 
                rx.count, 
                {rx.empty, rx.full, rx.almost_empty, rx.almost_full});
            end

            tx_prev = tx;
        end
    endtask

endclass
