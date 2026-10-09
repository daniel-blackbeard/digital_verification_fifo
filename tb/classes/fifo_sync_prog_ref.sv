class fifo_sync_prog_ref  #(int DATA_WIDTH=8, DEPTH=16);

    mailbox #(transaction) gen_ref;
    mailbox #(result)      ref_scr;

    logic [DATA_WIDTH-1:0] fifo_mem [DEPTH-1:0];
    int ptr;    
    logic r, w;

    function new(mailbox #(transaction) tra, mailbox #(result) res);
        this.gen_ref = tra;
        this.ref_scr = res;
        this.ptr = '0;
    endfunction

    task run();
        transaction tx;
        result      rx;

        forever begin
            tx = new();
            rx = new();
            gen_ref.get(tx);
            {w,r} = tx.op;
            if(w & (ptr < DEPTH)) begin
                fifo_mem[ptr] = tx.wr_data;
                ptr           = ptr + 1;
            end
            if(r  & (ptr >= 0)) begin
                fifo_mem   = {'0, fifo_mem[DEPTH-1:1]};
                rx.rd_data = fifo_mem[0];
                ptr        = ptr - 1;
            end
            rx.empty = (ptr == 0);
            rx.full  = (ptr == DEPTH);

            rx.empty = (ptr <= tx.th_empty);
            rx.full  = (ptr >= tx.th_full);

            ref_scr.put(rx);
        end
    endtask
endclass
