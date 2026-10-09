class result #(int DATA_WIDTH=8, DEPTH=16);

    logic [DATA_WIDTH-1:0]    rd_data;
    logic                     empty;
    logic                     full;
    logic                     almost_empty;
    logic                     almost_full;
    logic [$clog2(DEPTH):0]   count;

endclass
