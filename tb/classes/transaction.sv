class transaction #(int DATA_WIDTH=8, DEPTH=16);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        READ  = 2'b01,
        WRITE = 2'b10,
        BOTH  = 2'b11
    } t_op_type;

    rand logic [DATA_WIDTH-1:0]    wr_data;
    rand logic [$clog2(DEPTH)-1:0] th_empty;
    rand logic [$clog2(DEPTH)-1:0] th_full;
    rand t_op_type                     op;

    constraint c_op {
        op dist {
            IDLE  := 10,
            READ  := 40,
            WRITE := 40,
            BOTH  := 10
        };
    }

    constraint c_th_full  {th_full  > $bits(th_full)'(DEPTH/2);}
    constraint c_th_empty {th_empty < $bits(th_empty)'(DEPTH/2);}
endclass
