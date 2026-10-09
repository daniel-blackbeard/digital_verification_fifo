interface fifo_if #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic clk,
    input  logic rst
);
  
logic                     wr_en;
logic [DATA_WIDTH-1:0]    wr_data;
logic                     rd_en;
logic [DATA_WIDTH-1:0]    rd_data;
logic                     empty;
logic                     full;
logic                     almost_empty;
logic                     almost_full;
logic [$clog2(DEPTH)-1:0] almost_empty_tresh;
logic [$clog2(DEPTH)-1:0] almost_full_tresh;
logic [$clog2(DEPTH):0]   count;

endinterface
