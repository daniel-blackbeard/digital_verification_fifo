module fifo_sync_prog #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                     clk,
    input  logic                     rst,
    input  logic                     wr_en,
    input  logic [DATA_WIDTH-1:0]    wr_data,
    input  logic                     rd_en,
    output logic [DATA_WIDTH-1:0]    rd_data,
    output logic                     empty,
    output logic                     full,
    output logic                     almost_empty,
    output logic                     almost_full,
    input  logic [$clog2(DEPTH)-1:0] almost_empty_tresh,
    input  logic [$clog2(DEPTH)-1:0] almost_full_tresh,
    output logic [$clog2(DEPTH):0]   count
);

logic [DATA_WIDTH-1:0] fifo_mem [DEPTH-1:0];
logic [$clog2(DEPTH)-1:0] rd_ptr, wr_ptr;
logic [$clog2(DEPTH)-1:0] rd_ptr_p1, wr_ptr_p1;

always_ff @(posedge clk or posedge rst) begin : FIFO_LOGIC
    if(rst) begin
        rd_ptr <= '0;
        wr_ptr <= '0;
        count  <= '0;
    end else begin
        if(wr_en & ~full) begin
            fifo_mem[wr_ptr] <= wr_data;
            wr_ptr           <= wr_ptr_p1;
            count <= count + 1;
        end
        if(rd_en & ~empty) begin
            rd_data <= fifo_mem[rd_ptr];
            rd_ptr  <= rd_ptr_p1;
            count <= wr_en ? count : count - 1;
        end
    end
end

assign wr_ptr_p1 = wr_ptr + 1;
assign rd_ptr_p1 = rd_ptr + 1;

assign empty     = count == '0;
assign full      = count[$clog2(DEPTH)];

assign almost_empty = count[$clog2(DEPTH)-1:0] <= almost_empty_tresh;
assign almost_full  = count[$clog2(DEPTH)-1:0] >= almost_full_tresh;

endmodule
