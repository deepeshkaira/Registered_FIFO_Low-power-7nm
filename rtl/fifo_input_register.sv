module fifo_input_register #(
    parameter int FOLD_WIDTH = 23
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  en_i,
    input  logic [FOLD_WIDTH-1:0] data_i,
    input  logic                  data_valid_i,
    output logic                  data_ready_o,
    input  logic                  fifo_full_i,
    output logic [FOLD_WIDTH-1:0] fifo_data_o,
    output logic                  fifo_wr_en_o
);

    logic                  gated_clk;
    logic [FOLD_WIDTH-1:0] data_q;
    logic                  valid_q;
    logic                  input_accept;
    logic                  fifo_accept;
    logic                  data_valid_gated;
    logic                  fifo_full_gated;
    logic [FOLD_WIDTH-1:0] data_gated;

    gated_clk u_register_clock_gate (
        .clk_i       (clk),
        .en_i        (en_i),
        .clk_gated_o (gated_clk)
    );

    assign data_valid_gated = en_i ? data_valid_i : 1'b0;
    assign fifo_full_gated  = en_i ? fifo_full_i : 1'b0;
    assign data_gated       = en_i ? data_i : '0;

    assign fifo_accept  = en_i && valid_q && !fifo_full_gated;
    assign data_ready_o = en_i && (!valid_q || fifo_accept);
    assign input_accept = data_valid_gated && data_ready_o;

    assign fifo_data_o  = data_q;
    assign fifo_wr_en_o = fifo_accept;

    always_ff @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_q  <= '0;
            valid_q <= 1'b0;
        end
        else begin
            if (input_accept)
                data_q <= data_gated;

            case ({input_accept, fifo_accept})
                2'b10: valid_q <= 1'b1;
                2'b01: valid_q <= 1'b0;
                2'b11: valid_q <= 1'b1;
                default: valid_q <= valid_q;
            endcase
        end
    end

endmodule
