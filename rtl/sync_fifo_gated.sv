module sync_fifo #(
    parameter int FOLD_WIDTH = 23,
    parameter int DEPTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  en_i,
    input  logic                  wr_en_i,
    input  logic [FOLD_WIDTH-1:0] folded_history_i,
    input  logic                  rd_en_i,
    output logic                  fifo_full_o,
    output logic                  fifo_empty_o,
    output logic [FOLD_WIDTH-1:0] read_data_o
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic [ADDR_WIDTH:0] write_pointer;
    logic [ADDR_WIDTH:0] next_write_pointer;
    logic [ADDR_WIDTH:0] read_pointer;
    logic [ADDR_WIDTH:0] next_read_pointer;
    logic                  fifo_full_next;
    logic                  fifo_empty_next;
    logic                  write_enable;
    logic                  read_enable;
    logic                  gated_write_clk;
    logic                  gated_read_clk;
    logic [FOLD_WIDTH-1:0] fifo_mem [0:DEPTH-1];
    logic [FOLD_WIDTH-1:0] read_data_q;

    assign read_enable  = en_i && rd_en_i && !fifo_empty_o;
    assign write_enable = en_i && wr_en_i && (!fifo_full_o || read_enable);

    assign next_write_pointer = write_pointer + {{ADDR_WIDTH{1'b0}}, write_enable};
    assign next_read_pointer  = read_pointer + {{ADDR_WIDTH{1'b0}}, read_enable};
    assign fifo_empty_next = (next_read_pointer == next_write_pointer);
    assign fifo_full_next = (next_write_pointer[ADDR_WIDTH] != next_read_pointer[ADDR_WIDTH]) &&
                            (next_write_pointer[ADDR_WIDTH-1:0] == next_read_pointer[ADDR_WIDTH-1:0]);
    assign read_data_o = read_data_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_full_o  <= 1'b0;
            fifo_empty_o <= 1'b1;
        end
        else if (en_i) begin
            fifo_full_o  <= fifo_full_next;
            fifo_empty_o <= fifo_empty_next;
        end
    end

    gated_clk u_write_clock_gate (
        .clk_i       (clk),
        .en_i        (write_enable),
        .clk_gated_o (gated_write_clk)
    );

    gated_clk u_read_clock_gate (
        .clk_i       (clk),
        .en_i        (read_enable),
        .clk_gated_o (gated_read_clk)
    );

    always_ff @(posedge gated_write_clk or negedge rst_n) begin
        if (!rst_n)
            write_pointer <= '0;
        else begin
            write_pointer <= next_write_pointer;
            fifo_mem[write_pointer[ADDR_WIDTH-1:0]] <= folded_history_i;
        end
    end

    always_ff @(posedge gated_read_clk or negedge rst_n) begin
        if (!rst_n) begin
            read_pointer <= '0;
            read_data_q  <= '0;
        end
        else begin
            read_pointer <= next_read_pointer;
            read_data_q  <= fifo_mem[read_pointer[ADDR_WIDTH-1:0]];
        end
    end

endmodule
