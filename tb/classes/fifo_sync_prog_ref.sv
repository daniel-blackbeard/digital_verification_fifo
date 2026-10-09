class fifo_sync_prog_ref  #(int DATA_WIDTH=8, DEPTH=16);

    mailbox #(transaction) mon_ref;
    mailbox #(result)      ref_scr;

    logic [DATA_WIDTH-1:0] fifo_mem [DEPTH-1:0];
    int ptr;    
    logic r, w;

    function new(mailbox #(transaction) tra, mailbox #(result) res);
        this.mon_ref = tra;
        this.ref_scr = res;
        this.ptr = '0;
    endfunction

    task run();
        transaction tx;
        result      rx;

        forever begin
            tx = new();
            rx = new();
            mon_ref.get(tx);
            {w,r} = tx.op;
            if(w & (ptr < DEPTH)) begin
                fifo_mem[ptr] = tx.wr_data;
                ptr           = ptr + 1;
            end
            if(r  & (ptr > 0)) begin
                rx.rd_data = fifo_mem[0];
                fifo_mem   = {'0, fifo_mem[DEPTH-1:1]};
                ptr        = ptr - 1;
            end
            rx.empty = (ptr == 0);
            rx.full  = (ptr == DEPTH);

            rx.almost_empty = (ptr <= tx.th_empty);
            rx.almost_full  = (ptr >= tx.th_full);

            rx.count = $bits(rx.count)'(ptr);

            ref_scr.put(rx);
        end
    endtask
endclass
