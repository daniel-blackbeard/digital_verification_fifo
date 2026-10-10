class fifo_sync_prog_ref  #(int DATA_WIDTH=8, DEPTH=16);

    mailbox #(transaction) mon_ref;
    mailbox #(result)      ref_scr;

    logic [DATA_WIDTH-1:0] fifo_mem [DEPTH-1:0];
    logic [DATA_WIDTH-1:0] rd_data_temp;
    int ptr;    
    logic r, w, ra, wa;

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
            
            wa = w & (ptr < DEPTH);
            ra = r & (ptr > 0);

            if(wa) begin
                fifo_mem[ptr] = tx.wr_data;
                ptr           = ptr + 1;
            end
            if(ra) begin
                rd_data_temp = fifo_mem[0];
                fifo_mem     = {fifo_mem[0], fifo_mem[DEPTH-1:1]};
                ptr          = ptr - 1;
            end

            rx.rd_data = rd_data_temp;

            rx.empty = (ptr == 0);
            rx.full  = (ptr == DEPTH);

            rx.almost_empty = (ptr <= tx.th_empty);
            rx.almost_full  = (ptr >= tx.th_full);

            rx.count = $bits(rx.count)'(ptr);

            ref_scr.put(rx);
        end
    endtask
endclass
