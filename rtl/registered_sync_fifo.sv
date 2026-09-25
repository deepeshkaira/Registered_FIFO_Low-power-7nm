module registered_sync_fifo #(
    parameter int FOLD_WIDTH = 23,
    parameter int DEPTH = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  en_i,
    input  logic [FOLD_WIDTH-1:0] data_i,
    input  logic                  data_valid_i,
    input  logic                  rd_en_i,
    input  logic                  pd1_power_on_i,
    input  logic                  pd1_isolation_i,
    output logic [FOLD_WIDTH-1:0] read_data_o,
    output logic                  fifo_full_o,
    output logic                  fifo_empty_o
);

    logic                  register_data_ready;
    logic [FOLD_WIDTH-1:0] fifo_write_data;
    logic                  fifo_write_enable;
    logic                  fifo_full_internal;
    logic                  fifo_empty_internal;

    fifo_input_register #(.FOLD_WIDTH(FOLD_WIDTH)) u_input_register (
        .clk          (clk),
        .rst_n        (rst_n),
        .en_i         (en_i),
        .data_i       (data_i),
        .data_valid_i (data_valid_i),
        .data_ready_o (register_data_ready),
        .fifo_full_i  (fifo_full_internal),
        .fifo_data_o  (fifo_write_data),
        .fifo_wr_en_o (fifo_write_enable)
    );

    sync_fifo #(.FOLD_WIDTH(FOLD_WIDTH), .DEPTH(DEPTH)) u_fifo (
        .clk              (clk),
        .rst_n            (rst_n),
        .en_i             (en_i),
        .wr_en_i          (fifo_write_enable),
        .folded_history_i (fifo_write_data),
        .rd_en_i          (rd_en_i),
        .fifo_full_o      (fifo_full_internal),
        .fifo_empty_o     (fifo_empty_internal),
        .read_data_o      (read_data_o)
    );

    assign fifo_full_o  = fifo_full_internal;
    assign fifo_empty_o = fifo_empty_internal;

    // The power control ports are consumed by the UPF power switch and isolation strategies.
    logic unused_power_controls;
    assign unused_power_controls = pd1_power_on_i ^ pd1_isolation_i;

endmodule
