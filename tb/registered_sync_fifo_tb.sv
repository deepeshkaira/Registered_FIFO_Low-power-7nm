`timescale 1ns/1ps

import uvm_pkg::*;
import UPF::*;
`include "uvm_macros.svh"

package wrapper_params_pkg;
    parameter int FOLD_WIDTH = 23;
endpackage

import wrapper_params_pkg::*;

interface wrapper_if #(
    parameter int FOLD_WIDTH = 23
) (
    input logic clk
);

    logic                  rst_n;
    logic                  en_i;
    logic [FOLD_WIDTH-1:0] data_i;
    logic                  data_valid_i;
    logic                  rd_en_i;

    // for upf
logic                  pd1_power_on_i;
    logic                  pd1_isolation_i;

    logic [FOLD_WIDTH-1:0] read_data_o;
    logic                  fifo_full_o;
    logic                  fifo_empty_o;

    clocking drv_cb @(negedge clk);
        output rst_n;
        output en_i;
        output data_i;
        output data_valid_i;
        output rd_en_i;
        output pd1_power_on_i;
        output pd1_isolation_i;

        input read_data_o;
        input fifo_full_o;
        input fifo_empty_o;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;

        input rst_n;
        input en_i;
        input data_i;
        input data_valid_i;
        input rd_en_i;
        input fifo_full_o;
        input fifo_empty_o;
        input pd1_power_on_i;
        input pd1_isolation_i;
    endclocking

endinterface


/// sequence item
class wrapper_seq_item extends uvm_sequence_item;

    rand logic                  rst_n;
    rand logic                  en_i;
    rand logic [FOLD_WIDTH-1:0] data_i;
    rand logic                  data_valid_i;
    rand logic                  rd_en_i;

    // for upf
    rand logic                  pd1_power_on_i;
    rand logic                  pd1_isolation_i;

    logic [FOLD_WIDTH-1:0]      read_data_o;
    logic                       fifo_full_o;
    logic                       fifo_empty_o;

    `uvm_object_utils_begin(wrapper_seq_item)
        `uvm_field_int(rst_n,        UVM_DEFAULT)
        `uvm_field_int(en_i,         UVM_DEFAULT)
        `uvm_field_int(data_i,       UVM_HEX)
        `uvm_field_int(data_valid_i, UVM_DEFAULT)
        `uvm_field_int(rd_en_i,      UVM_DEFAULT)
        `uvm_field_int(read_data_o,  UVM_HEX)
        `uvm_field_int(fifo_full_o,  UVM_DEFAULT)
        `uvm_field_int(fifo_empty_o, UVM_DEFAULT)
        // for upf
        `uvm_field_int(pd1_power_on_i,      UVM_DEFAULT)
        `uvm_field_int(pd1_isolation_i,     UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "wrapper_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "rst_n=%0b en_i=%0b data_i=0x%0h data_valid_i=%0b rd_en_i=%0b read_data_o=0x%0h fifo_full_o=%0b fifo_empty_o=%0b",
            rst_n, en_i, data_i, data_valid_i, rd_en_i,
            read_data_o, fifo_full_o, fifo_empty_o
        );
    endfunction

endclass


/// base sequence
class wrapper_base_sequence extends uvm_sequence #(wrapper_seq_item);

    `uvm_object_utils(wrapper_base_sequence)

    function new(string name = "wrapper_base_sequence");
        super.new(name);
    endfunction

    // task drive_cycle(
    //     input logic                  rst_n,
    //     input logic                  en_i,
    //     input logic [FOLD_WIDTH-1:0] data_i,
    //     input logic                  data_valid_i,
    //     input logic                  rd_en_i
    // );
    //     wrapper_seq_item req;

    //     req = wrapper_seq_item::type_id::create("req");
    //     start_item(req);

    //     req.rst_n        = rst_n;
    //     req.en_i         = en_i;
    //     req.data_i       = data_i;
    //     req.data_valid_i = data_valid_i;
    //     req.rd_en_i      = rd_en_i;

    //     finish_item(req);
    // endtask

    // this task contains the upf control signals as well
    task drive_cycle(
        input logic                  rst_n,
        input logic                  en_i,
        input logic [FOLD_WIDTH-1:0] data_i,
        input logic                  data_valid_i,
        input logic                  rd_en_i,
        input logic                  pd1_power_on_i  = 1'b1,
        input logic                  pd1_isolation_i = 1'b0
    );
        wrapper_seq_item req;

        req = wrapper_seq_item::type_id::create("req");
        start_item(req);

        req.rst_n              = rst_n;
        req.en_i               = en_i;
        req.data_i             = data_i;
        req.data_valid_i       = data_valid_i;
        req.rd_en_i            = rd_en_i;
        req.pd1_power_on_i     = pd1_power_on_i;
        req.pd1_isolation_i    = pd1_isolation_i;

        finish_item(req);
    endtask


    // power control task
    task control_pd1_power(
        input logic        power_on,
        input logic        isolation,
        input int unsigned cycles = 1
    );
        repeat (cycles)
            drive_cycle(1'b1, 1'b0, '0, 1'b0, 1'b0, power_on, isolation);
    endtask


    task apply_reset(input int unsigned cycles = 2);
        repeat (cycles)
            drive_cycle(1'b0, 1'b0, '0, 1'b0, 1'b0);

        drive_cycle(1'b1, 1'b1, '0, 1'b0, 1'b0);
    endtask

    task idle_cycle();
        drive_cycle(1'b1, 1'b1, '0, 1'b0, 1'b0);
    endtask

    task idle_cycles(input int unsigned cycles);
        repeat (cycles)
            idle_cycle();
    endtask

    task write_data(input logic [FOLD_WIDTH-1:0] data_i);
        drive_cycle(1'b1, 1'b1, data_i, 1'b1, 1'b0);
    endtask

    task read_fifo();
        drive_cycle(1'b1, 1'b1, '0, 1'b0, 1'b1);
    endtask

    task write_and_read(input logic [FOLD_WIDTH-1:0] data_i);
        drive_cycle(1'b1, 1'b1, data_i, 1'b1, 1'b1);
    endtask

    task disable_block(input int unsigned cycles = 1);
        repeat (cycles)
            drive_cycle(1'b1, 1'b0, '0, 1'b0, 1'b0);
    endtask

endclass


// wrapper test seq
class wrapper_test_sequence extends wrapper_base_sequence;

    `uvm_object_utils(wrapper_test_sequence)

    function new(string name = "wrapper_test_sequence");
        super.new(name);
    endfunction

    task body();
        logic [FOLD_WIDTH-1:0] data_value;

        `uvm_info(get_type_name(), "Starting basic register and FIFO wrapper sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        for (int i = 0; i < 12; i++) begin
            data_value = 'h101 + i;
            write_data(data_value);
        end

        // Flush the final value from the input register into the FIFO.
        idle_cycles(2);

        for (int i = 0; i < 9; i++)
            read_fifo();

        idle_cycles(3);

    for (int i = 0; i < 12; i++) begin
            data_value = 'h111 + i;
            write_data(data_value);
        end

        // Flush the final value from the input register into the FIFO.
        idle_cycles(2);

        for (int i = 0; i < 9; i++)
            read_fifo();

    idle_cycles(3);

    for (int i = 0; i < 12; i++) begin
            data_value = 'h111 + i;
            write_data(data_value);
        end

        // Flush the final value from the input register into the FIFO.
        idle_cycles(2);

        for (int i = 0; i < 9; i++)
            read_fifo();

    idle_cycles(3);


        `uvm_info(get_type_name(), "Basic register and FIFO wrapper sequence completed", UVM_LOW)
    endtask

endclass


/// wrapper flag sequence
class wrapper_flag_sequence extends wrapper_base_sequence;

    `uvm_object_utils(wrapper_flag_sequence)

    function new(string name = "wrapper_flag_sequence");
        super.new(name);
    endfunction

    task body();
        logic [FOLD_WIDTH-1:0] data_value;

        `uvm_info(get_type_name(), "Starting FIFO flag sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        for (int run = 0; run < 2; run++) begin
            for (int i = 0; i < 8; i++) begin
                data_value = 'h501 + (run * 'h100) + i;
                write_data(data_value);
            end

            // Move the eighth value from the register into the FIFO.
            idle_cycles(3);

            `uvm_info(get_type_name(), "FIFO should now be full", UVM_LOW)

            read_fifo();
            idle_cycles(2);

            `uvm_info(get_type_name(), "FIFO should now be neither full nor empty", UVM_LOW)

            for (int i = 0; i < 7; i++)
                read_fifo();

            idle_cycles(3);

            `uvm_info(get_type_name(), "FIFO should now be empty", UVM_LOW)
        end

        `uvm_info(get_type_name(), "FIFO flag sequence completed", UVM_LOW)
    endtask

endclass



/// simultaneous write and read
class wrapper_simultaneous_sequence extends wrapper_base_sequence;

    `uvm_object_utils(wrapper_simultaneous_sequence)

    function new(string name = "wrapper_simultaneous_sequence");
        super.new(name);
    endfunction

     task body();
        logic [FOLD_WIDTH-1:0] data_value;

        `uvm_info(get_type_name(), "Starting simultaneous read and write sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        for (int i = 0; i < 8; i++) begin
            data_value = 'h601 + i;
            write_data(data_value);
        end

        idle_cycles(3);

        // FIFO is full, but the input register is empty and can accept 0x701.
        write_data('h701);

        // First attempt reads the FIFO, but the full register cannot accept 0x702.
        write_and_read('h702);

        // FIFO is no longer full, so retry 0x702.
        write_and_read('h702);

        // Continue simultaneous reads and writes.
        for (int i = 0; i < 5; i++) begin
            data_value = 'h703 + i;
            write_and_read(data_value);
        end

        // Move the final register value into the FIFO.
        idle_cycles(3);

        for (int i = 0; i < 8; i++)
            read_fifo();

        idle_cycles(3);

        `uvm_info(get_type_name(), "Simultaneous read and write sequence completed", UVM_LOW)
    endtask

endclass


/// wrapper control sequence
class wrapper_control_sequence extends wrapper_base_sequence;

    `uvm_object_utils(wrapper_control_sequence)

    function new(string name = "wrapper_control_sequence");
        super.new(name);
    endfunction

    task body();
        logic [FOLD_WIDTH-1:0] data_value;

        `uvm_info(get_type_name(), "Starting wrapper control sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        for (int i = 0; i < 5; i++) begin
            data_value = 'h701 + i;
            write_data(data_value);
        end

        // Present read and write requests while the wrapper is disabled.
        for (int i = 0; i < 3; i++) begin
            data_value = 'h711 + i;
            drive_cycle(1'b1, 1'b0, data_value, 1'b1, 1'b1);
        end

        // Resume operation and move the pending register value into the FIFO.
        idle_cycles(2);

        for (int i = 0; i < 5; i++)
            read_fifo();

        idle_cycles(2);

        // Leave valid data in both the FIFO and the input register.
        for (int i = 0; i < 6; i++) begin
            data_value = 'h801 + i;
            write_data(data_value);
        end

        // Reset while nonzero data remains stored.
        apply_reset(2);
        idle_cycles(2);

        // Confirm that only post-reset data can be read.
        for (int i = 0; i < 4; i++) begin
            data_value = 'h901 + i;
            write_data(data_value);
        end

        idle_cycles(2);

        for (int i = 0; i < 4; i++)
            read_fifo();

        idle_cycles(3);

        `uvm_info(get_type_name(), "Wrapper control sequence completed", UVM_LOW)
    endtask

endclass



/// input affter some gaps
class wrapper_input_gap_sequence extends wrapper_base_sequence;

    `uvm_object_utils(wrapper_input_gap_sequence)

    function new(string name = "wrapper_input_gap_sequence");
        super.new(name);
    endfunction

    task body();
        logic [FOLD_WIDTH-1:0] data_value;
        int unsigned items_in_run;

        `uvm_info(get_type_name(), "Starting varied input-gap sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        for (int run = 0; run < 6; run++) begin
        if ((run % 2) == 0) begin
            `uvm_info(get_type_name(), $sformatf("Run %0d: filling FIFO", run + 1), UVM_LOW)

            items_in_run = 8;

            for (int i = 0; i < items_in_run; i++) begin
                data_value = 'hB01 + (run * 'h20) + i;
                write_data(data_value);
            end

            // Transfer the eighth value from the register and observe full.
            idle_cycles(3);
        end
        else begin
            `uvm_info(get_type_name(), $sformatf("Run %0d: using input gaps", run + 1), UVM_LOW)

            items_in_run = 6;

            for (int i = 0; i < items_in_run; i++) begin
                data_value = 'hB01 + (run * 'h20) + i;
                write_data(data_value);
                idle_cycles((i % 2) + 1);
            end

            idle_cycles(2);
        end

        for (int i = 0; i < items_in_run; i++) begin
            read_fifo();

            if ((i % 3) == 2)
                idle_cycle();
        end

        idle_cycles(3);
        end

        `uvm_info(get_type_name(), "Varied input-gap sequence completed", UVM_LOW)
    endtask

endclass



/// wrapper full reecovery
class wrapper_full_recovery_sequence extends wrapper_base_sequence;

     `uvm_object_utils(wrapper_full_recovery_sequence)

     function new(string name = "wrapper_full_recovery_sequence");
        super.new(name);
        endfunction

        task body();
        logic [FOLD_WIDTH-1:0] data_value;
        logic [FOLD_WIDTH-1:0] blocked_value;

        `uvm_info(get_type_name(), "Starting FIFO full recovery sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        for (int run = 0; run < 3; run++) begin
            for (int i = 0; i < 8; i++) begin
                data_value = 'hD01 + (run * 'h20) + i;
                write_data(data_value);
            end

            idle_cycles(3);

            // The FIFO is full, but the empty register accepts one value.
            data_value = 'hD09 + (run * 'h20);
            write_data(data_value);

            // The FIFO and register are now occupied, so this attempt is rejected.
            blocked_value = 'hD0A + (run * 'h20);
            write_data(blocked_value);

            // Create one FIFO location.
            read_fifo();

            // Retry the previously rejected value.
            write_data(blocked_value);

            // Drain the remaining FIFO and register contents.
            for (int i = 0; i < 9; i++)
                read_fifo();

            idle_cycles(3);
        end

        `uvm_info(get_type_name(), "FIFO full recovery sequence completed", UVM_LOW)
        endtask

    endclass



/// power drive sequence
    class wrapper_power_cycle_sequence extends wrapper_base_sequence;

    `uvm_object_utils(wrapper_power_cycle_sequence)

    function new(string name = "wrapper_power_cycle_sequence");
        super.new(name);
    endfunction

    task body();
        logic [FOLD_WIDTH-1:0] data_value;

        `uvm_info(get_type_name(), "Starting PD1 power-cycle sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        // Storing six values in the FIFO.
        for (int i = 0; i < 6; i++) begin
            data_value = 'hE01 + i;
            write_data(data_value);
        end

        // Transfer the final register value into the FIFO - add some idle cycles
        idle_cycles(2);

        `uvm_info(get_type_name(), "Asserting isolation before switching PD1 off", UVM_LOW)

        // PD1 remains powered while its outputs are isolated.
        control_pd1_power(1'b1, 1'b1, 2);

        `uvm_info(get_type_name(), "Switching PD1 off while isolation remains asserted", UVM_LOW)

        // Switch PD1 off and allow its internal state to become corrupt.
        control_pd1_power(1'b0, 1'b1, 3);

        `uvm_info(get_type_name(), "Reading FIFO data while PD1 is off", UVM_LOW)

        // PD2 remains powered, so FIFO reads should continue to work.
        // Isolation keeps the PD1 write-data and write-enable outputs at zero.
        for (int i = 0; i < 3; i++)
            drive_cycle(1'b1, 1'b1, '0, 1'b0, 1'b1, 1'b0, 1'b1);

        // Keep PD1 off for additional observation cycles.
        control_pd1_power(1'b0, 1'b1, 2);

        `uvm_info(get_type_name(), "Restoring power to PD1 while isolation remains asserted", UVM_LOW)

        // Power returns first. Isolation must remain asserted.
        control_pd1_power(1'b1, 1'b1, 2);

        `uvm_info(get_type_name(), "Resetting the design after PD1 power restoration", UVM_LOW)

        // PD1 is nonretained, so its register state must be reinitialized.
        // Isolation remains asserted throughout reset.
        repeat (2)
            drive_cycle(1'b0, 1'b0, '0, 1'b0, 1'b0, 1'b1, 1'b1);

        drive_cycle(1'b1, 1'b0, '0, 1'b0, 1'b0, 1'b1, 1'b1);

        `uvm_info(get_type_name(), "Releasing isolation after power and reset are stable", UVM_LOW)

        // Return to normal powered operation.
        control_pd1_power(1'b1, 1'b0, 2);

        // Verify that normal register-to-FIFO traffic resumes.
        for (int i = 0; i < 4; i++) begin
            data_value = 'hF01 + i;
            write_data(data_value);
        end

        idle_cycles(2);

        for (int i = 0; i < 4; i++)
            read_fifo();

        idle_cycles(3);

        `uvm_info(get_type_name(), "PD1 power-cycle sequence completed", UVM_LOW)
    endtask

endclass


/// sequence with turning off the isolation cell to see the X propagation in the design
class wrapper_no_isolation_sequence extends wrapper_base_sequence;

     `uvm_object_utils(wrapper_no_isolation_sequence)

    function new(string name = "wrapper_no_isolation_sequence");
        super.new(name);
    endfunction

    task body();
        logic [FOLD_WIDTH-1:0] data_value;

        `uvm_info(get_type_name(), "Starting PD1 shutdown without isolation", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        // Store known values in the FIFO before powering PD1 off.
        for (int i = 0; i < 6; i++) begin
            data_value = 'hA01 + i;
            write_data(data_value);
        end

        // Flush the last register value into the FIFO.
        idle_cycles(2);

        `uvm_info(get_type_name(), "Switching PD1 off while isolation remains disabled", UVM_LOW)

        // Intentional incorrect power sequence:
        // PD1 is switched off without asserting isolation.
        control_pd1_power(1'b0, 1'b0, 6);

        `uvm_info(get_type_name(), "Activating PD2 while unisolated PD1 outputs are unknown", UVM_LOW)

        // PD2 remains powered. These cycles expose it to the unisolated
        // write-data and write-enable outputs coming from powered-off PD1.
        for (int i = 0; i < 4; i++)
            drive_cycle(1'b1, 1'b1, '0, 1'b0, 1'b1, 1'b0, 1'b0);

        // Continue observing the unprotected crossing.
        control_pd1_power(1'b0, 1'b0, 5);

        `uvm_info(get_type_name(), "Restoring PD1 power without isolation", UVM_LOW)

        // Power restoration does not recover corrupted register state.
        control_pd1_power(1'b1, 1'b0, 2);

        // Reset both blocks to recover from the intentionally corrupted state.
        repeat (2)
            drive_cycle(1'b0, 1'b0, '0, 1'b0, 1'b0, 1'b1, 1'b0);

        drive_cycle(1'b1, 1'b0, '0, 1'b0, 1'b0, 1'b1, 1'b0);
        idle_cycles(2);

        `uvm_info(get_type_name(), "PD1 shutdown without isolation completed", UVM_LOW)
    endtask



endclass





/// sequence for generating the saif file
class wrapper_power_activity_sequence extends wrapper_base_sequence;

    `uvm_object_utils(wrapper_power_activity_sequence)

    function new(string name = "wrapper_power_activity_sequence");
        super.new(name);
    endfunction

    function automatic logic [FOLD_WIDTH-1:0] activity_word(input int unsigned index);
        case (index % 6)
            0: return 23'h000001;
            1: return 23'h7FFFFE;
            2: return 23'h555555;
            3: return 23'h2AAAAA;
            4: return 23'h0F0F0F;
            default: return 23'h70F0F0 ^ index;
        endcase
    endfunction

    task body();
        logic [FOLD_WIDTH-1:0] data_value;

        `uvm_info(get_type_name(), "Starting complete wrapper power-activity sequence", UVM_LOW)

        apply_reset(3);
        idle_cycles(2);

        // Sparse writes with clock-gating opportunities.
        for (int i = 0; i < 8; i++) begin
            data_value = activity_word(i);
            write_data(data_value);
            idle_cycles((i % 3) + 1);
        end

        // Read the FIFO with intermittent idle cycles.
        for (int i = 0; i < 8; i++) begin
            read_fifo();

            if ((i % 3) == 2)
                idle_cycle();
        end

        idle_cycles(3);

        // Burst writes until the FIFO becomes full.
        for (int i = 0; i < 8; i++) begin
            data_value = activity_word(i + 8);
            write_data(data_value);
        end

        idle_cycles(3);

        // Store one pending value in the input register while the FIFO is full.
        data_value = activity_word(16);
        write_data(data_value);

        // Create one FIFO location.
        read_fifo();

        // Transfer the pending value and accept a new register value.
        data_value = activity_word(17);
        write_data(data_value);

        // Create another FIFO location for simultaneous traffic.
        read_fifo();

        // Exercise simultaneous reads and writes.
        for (int i = 0; i < 8; i++) begin
            data_value = activity_word(i + 18);
            write_and_read(data_value);
        end

        // Transfer the final register value.
        idle_cycles(2);

        // Drain the FIFO.
        for (int i = 0; i < 8; i++)
            read_fifo();

        idle_cycles(3);

        // Create register and FIFO activity before disabling the wrapper.
        for (int i = 0; i < 4; i++) begin
            data_value = activity_word(i + 26);
            write_data(data_value);
        end

        // Disable the wrapper to exercise its clock-gating behavior.
        disable_block(8);

        // Transfer the pending register value after re-enabling the wrapper.
        idle_cycles(2);

        for (int i = 0; i < 4; i++)
            read_fifo();

        idle_cycles(3);

        // Load the FIFO before switching PD1 off.
        for (int i = 0; i < 6; i++) begin
            data_value = activity_word(i + 30);
            write_data(data_value);
        end

        idle_cycles(2);

        // Assert isolation before switching PD1 off.
        control_pd1_power(1'b1, 1'b1, 2);

        // Keep PD1 off while the FIFO remains powered.
        control_pd1_power(1'b0, 1'b1, 6);

        // Read three values from the always-on FIFO while PD1 is off.
        for (int i = 0; i < 3; i++)
            drive_cycle(1'b1, 1'b1, '0, 1'b0, 1'b1, 1'b0, 1'b1);

        control_pd1_power(1'b0, 1'b1, 3);

        // Restore PD1 power while keeping isolation asserted.
        control_pd1_power(1'b1, 1'b1, 2);

        // Reset the nonretained register state after power restoration.
        repeat (2)
            drive_cycle(1'b0, 1'b0, '0, 1'b0, 1'b0, 1'b1, 1'b1);

        drive_cycle(1'b1, 1'b0, '0, 1'b0, 1'b0, 1'b1, 1'b1);

        // Release isolation after power and reset are stable.
        control_pd1_power(1'b1, 1'b0, 2);

        // Generate activity after the power cycle.
        for (int i = 0; i < 4; i++) begin
            data_value = activity_word(i + 36);
            write_data(data_value);
        end

        idle_cycles(2);

        // Sustained simultaneous read and write activity.
        for (int i = 0; i < 16; i++) begin
            data_value = activity_word(i + 40);
            write_and_read(data_value);
        end

        idle_cycles(2);

        // Four entries remain after the balanced traffic.
        for (int i = 0; i < 4; i++)
            read_fifo();

        idle_cycles(4);

        `uvm_info(get_type_name(), "Complete wrapper power-activity sequence completed", UVM_LOW)
    endtask

endclass





// sequncer
class wrapper_sequencer extends uvm_sequencer #(wrapper_seq_item);

    `uvm_component_utils(wrapper_sequencer)

    function new(string name = "wrapper_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass


// driver
class wrapper_driver extends uvm_driver #(wrapper_seq_item);

    `uvm_component_utils(wrapper_driver)

    virtual wrapper_if #(FOLD_WIDTH) vif;

    function new(string name = "wrapper_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wrapper_if #(FOLD_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface was not provided to the driver")
    endfunction

    task run_phase(uvm_phase phase);
        initialize_signals();

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task initialize_signals();
        vif.rst_n        <= 1'b0;
        vif.en_i         <= 1'b0;
        vif.data_i       <= '0;
        vif.data_valid_i <= 1'b0;
        vif.rd_en_i      <= 1'b0;

        /// signals for power
        vif.pd1_power_on_i     <= 1'b1;
        vif.pd1_isolation_i    <= 1'b0;
    endtask

    task drive_item(wrapper_seq_item item);
        @(vif.drv_cb);

        vif.drv_cb.rst_n        <= item.rst_n;
        vif.drv_cb.en_i         <= item.en_i;
        vif.drv_cb.data_i       <= item.data_i;
        vif.drv_cb.data_valid_i <= item.data_valid_i;
        vif.drv_cb.rd_en_i      <= item.rd_en_i;

        /// signals for power
        vif.drv_cb.pd1_power_on_i     <= item.pd1_power_on_i;
        vif.drv_cb.pd1_isolation_i    <= item.pd1_isolation_i;
    endtask

endclass


// monitor
class wrapper_monitor extends uvm_monitor;

    `uvm_component_utils(wrapper_monitor)

    virtual wrapper_if #(FOLD_WIDTH) vif;
    uvm_analysis_port #(wrapper_seq_item) analysis_port;

    function new(string name = "wrapper_monitor", uvm_component parent = null);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wrapper_if #(FOLD_WIDTH))::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface was not provided to the monitor")
    endfunction

    task run_phase(uvm_phase phase);
        wrapper_seq_item item;

        forever begin
            @(vif.mon_cb);

            item = wrapper_seq_item::type_id::create("item");

            item.rst_n        = vif.mon_cb.rst_n;
            item.en_i         = vif.mon_cb.en_i;
            item.data_i       = vif.mon_cb.data_i;
            item.data_valid_i = vif.mon_cb.data_valid_i;
            item.rd_en_i      = vif.mon_cb.rd_en_i;
            item.fifo_full_o  = vif.mon_cb.fifo_full_o;
            item.fifo_empty_o = vif.mon_cb.fifo_empty_o;

            // upf signals
            item.pd1_power_on_i     = vif.mon_cb.pd1_power_on_i;
            item.pd1_isolation_i    = vif.mon_cb.pd1_isolation_i;

            #1ps;
            item.read_data_o = vif.read_data_o;

            analysis_port.write(item);
        end
    endtask

endclass



/// scoreboard
class wrapper_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(wrapper_scoreboard)

    localparam int FIFO_DEPTH = 8;

    uvm_analysis_imp #(wrapper_seq_item, wrapper_scoreboard) analysis_export;

    logic [FOLD_WIDTH-1:0] model_register_data;
    logic                  model_register_valid;
    logic [FOLD_WIDTH-1:0] model_fifo[$];
    logic [FOLD_WIDTH-1:0] expected_read_data;

    int unsigned cycle_count;
    int unsigned presented_input_count;
    int unsigned accepted_input_count;
    int unsigned rejected_input_cycle_count;
    int unsigned fifo_write_count;
    int unsigned fifo_read_count;
    int unsigned error_count;

    function new(string name = "wrapper_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        model_register_data       = '0;
        model_register_valid      = 1'b0;
        expected_read_data        = '0;
        cycle_count               = 0;
        presented_input_count     = 0;
        accepted_input_count      = 0;
        rejected_input_cycle_count = 0;
        fifo_write_count          = 0;
        fifo_read_count           = 0;
        error_count               = 0;
        model_fifo.delete();
    endfunction

    function string get_fifo_contents();
        string fifo_contents;

        fifo_contents = "[";

        foreach (model_fifo[i]) begin
            if (i != 0)    fifo_contents = {fifo_contents, ", "};
            fifo_contents = {fifo_contents, $sformatf("0x%0h", model_fifo[i])};
        end

        fifo_contents = {fifo_contents, "]"};
        return fifo_contents;
    endfunction

    function void write(wrapper_seq_item item);
        logic expected_full;
        logic expected_empty;
        logic register_to_fifo;
        logic register_ready;
        logic input_accept;
        logic read_accept;
        logic [FOLD_WIDTH-1:0] expected_read;

        cycle_count++;

        if (!item.rst_n) begin
            model_register_data  = '0;
            model_register_valid = 1'b0;
            expected_read_data   = '0;
            model_fifo.delete();

            if (item.fifo_full_o !== 1'b0) begin
                `uvm_error(get_type_name(), "fifo_full_o must be low during reset")
                error_count++;
            end

            if (item.fifo_empty_o !== 1'b1) begin
                `uvm_error(get_type_name(), "fifo_empty_o must be high during reset")
                error_count++;
            end

            if (item.read_data_o !== '0) begin
                `uvm_error(get_type_name(), "read_data_o must be zero during reset")
                error_count++;
            end

            return;
        end

        expected_full  = (model_fifo.size() == FIFO_DEPTH);
        expected_empty = (model_fifo.size() == 0);

        if (item.fifo_full_o !== expected_full) begin
            `uvm_error(get_type_name(), $sformatf(
                "fifo_full_o mismatch: expected=%0b actual=%0b",
                expected_full, item.fifo_full_o
            ))
            error_count++;
        end

        if (item.fifo_empty_o !== expected_empty) begin
            `uvm_error(get_type_name(), $sformatf(
                "fifo_empty_o mismatch: expected=%0b actual=%0b",
                expected_empty, item.fifo_empty_o
            ))
            error_count++;
        end

        register_to_fifo = item.en_i && model_register_valid && !expected_full;
        register_ready   = item.en_i && (!model_register_valid || register_to_fifo);
        input_accept     = item.data_valid_i && register_ready;
        read_accept      = item.en_i && item.rd_en_i && !expected_empty;

        if (item.data_valid_i)
            presented_input_count++;

        if (input_accept)
            accepted_input_count++;
        else if (item.data_valid_i)
            rejected_input_cycle_count++;

        if (read_accept) begin
            expected_read = model_fifo.pop_front();
            expected_read_data = expected_read;
            fifo_read_count++;

            if (item.read_data_o !== expected_read) begin
                `uvm_error(get_type_name(), $sformatf(
                    "read_data_o mismatch: expected=0x%0h actual=0x%0h",
                    expected_read, item.read_data_o
                ))
                error_count++;
            end
        end
        else if (item.read_data_o !== expected_read_data) begin
            `uvm_error(get_type_name(), $sformatf(
                "read_data_o changed without an accepted read: expected=0x%0h actual=0x%0h",
                expected_read_data, item.read_data_o
            ))
            error_count++;
        end

        if (register_to_fifo) begin
            model_fifo.push_back(model_register_data);
            fifo_write_count++;
        end

        if (input_accept)
            model_register_data = item.data_i;

        model_register_valid = input_accept || (model_register_valid && !register_to_fifo);

        `uvm_info(get_type_name(), $sformatf(
        "cycle=%0d rst_n=%0b en_i=%0b data_i=0x%0h data_valid_i=%0b rd_en_i=%0b pd1_power_on_i=%0b pd1_isolation_i=%0b read_data_o=0x%0h fifo_full_o=%0b fifo_empty_o=%0b register_data=0x%0h register_valid=%0b fifo_size=%0d fifo_contents=%s",
        cycle_count, item.rst_n, item.en_i, item.data_i,
        item.data_valid_i, item.rd_en_i,
        item.pd1_power_on_i, item.pd1_isolation_i,
        item.read_data_o, item.fifo_full_o, item.fifo_empty_o,
        model_register_data, model_register_valid,
        model_fifo.size(), get_fifo_contents()
    ), UVM_MEDIUM)

    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info(get_type_name(), $sformatf(
            "SUMMARY: cycles=%0d presented_inputs=%0d accepted_inputs=%0d rejected_input_cycles=%0d fifo_writes=%0d fifo_reads=%0d pending_register=%0b pending_fifo=%0d errors=%0d",
            cycle_count, presented_input_count, accepted_input_count,
            rejected_input_cycle_count, fifo_write_count, fifo_read_count,
            model_register_valid, model_fifo.size(), error_count
        ), UVM_LOW)
    endfunction

endclass



/// agent class
class wrapper_agent extends uvm_agent;

    `uvm_component_utils(wrapper_agent)

    wrapper_sequencer sequencer;
    wrapper_driver    driver;
    wrapper_monitor   monitor;

    function new(string name = "wrapper_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor = wrapper_monitor::type_id::create("monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = wrapper_sequencer::type_id::create("sequencer", this);
            driver    = wrapper_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass



/// environment class
class wrapper_env extends uvm_env;

    `uvm_component_utils(wrapper_env)

    wrapper_agent      agent;
    wrapper_scoreboard scoreboard;

    function new(string name = "wrapper_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent      = wrapper_agent::type_id::create("agent", this);
        scoreboard = wrapper_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.analysis_port.connect(scoreboard.analysis_export);
    endfunction

endclass



///test class
class wrapper_test extends uvm_test;

    `uvm_component_utils(wrapper_test)

    wrapper_env env;

    function new(string name = "wrapper_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = wrapper_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        wrapper_test_sequence test_seq;
    wrapper_flag_sequence flag_seq;
    wrapper_simultaneous_sequence simul_seq;
    wrapper_control_sequence cont_seq;
    wrapper_input_gap_sequence gap_seq;
    wrapper_full_recovery_sequence recvr_seq;
    wrapper_power_cycle_sequence power_seq;
    wrapper_no_isolation_sequence power_seq_isolation_off;
    wrapper_power_activity_sequence power_Activity;

        phase.raise_objection(this);
/*
        test_seq = wrapper_test_sequence::type_id::create("test_seq");
        test_seq.start(env.agent.sequencer);

    flag_seq = wrapper_flag_sequence::type_id::create("flag_seq");
        flag_seq.start(env.agent.sequencer);

    cont_seq = wrapper_control_sequence::type_id::create("cont_seq");
        cont_seq.start(env.agent.sequencer);

    gap_seq = wrapper_input_gap_sequence::type_id::create("gap_seq");
        gap_seq.start(env.agent.sequencer);

    recvr_seq = wrapper_full_recovery_sequence::type_id::create("recvr_seq");
        recvr_seq.start(env.agent.sequencer);

    simul_seq = wrapper_simultaneous_sequence::type_id::create("simul_seq");
        simul_seq.start(env.agent.sequencer);

    power_seq = wrapper_power_cycle_sequence::type_id::create("power_seq");
        power_seq.start(env.agent.sequencer);

    power_seq_isolation_off = wrapper_no_isolation_sequence::type_id::create("power_seq_isolation_off");
        power_seq_isolation_off.start(env.agent.sequencer);
*/
    power_Activity = wrapper_power_activity_sequence::type_id::create("power_Activity");
        power_Activity.start(env.agent.sequencer);


        phase.drop_objection(this);
    endtask

endclass



/// wrapper tb
module registered_sync_fifo_tb;

    logic clk;

    /// for upf use
    // logic pd1_power_on_i;    // control bit for power switch
    // logic pd1_isolation_i;    // isolation cell control

bit vdd_0p7_status;
    bit vdd_0p6_status;
bit vss_status;

    wrapper_if #(.FOLD_WIDTH(FOLD_WIDTH)) vif (.clk(clk));

    registered_sync_fifo #(.FOLD_WIDTH(FOLD_WIDTH)) dut (
        .clk          (clk),
        .rst_n        (vif.rst_n),
        .en_i         (vif.en_i),
        .data_i       (vif.data_i),
        .data_valid_i (vif.data_valid_i),
        .rd_en_i      (vif.rd_en_i),
        .read_data_o  (vif.read_data_o),
        .fifo_full_o  (vif.fifo_full_o),
        .fifo_empty_o (vif.fifo_empty_o),
        .pd1_power_on_i(vif.pd1_power_on_i),                /// for power switch control
        .pd1_isolation_i(vif.pd1_isolation_i)                /// for isolation cell control
    );

    /// commenting them out for the design so that they can be driven only by the driver
    // upf signals
    // initial
    // begin
    //     pd1_power_on_i = 1'b1;        // initialize of power for PD1 putting it high for now
    //     pd1_isolation_i = 1'b0;        // initialized isolation cell to 0
    // end

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        uvm_config_db#(virtual wrapper_if #(FOLD_WIDTH))::set(null, "uvm_test_top.env.agent.*", "vif", vif);
        run_test("wrapper_test");
    end


    initial begin
        vdd_0p7_status = supply_on("VDD_0P7", 0.7);
        vdd_0p6_status = supply_on("VDD_0P6", 0.6);
        vss_status = supply_on("VSS", 0.0);

        if (!vss_status)
        $fatal(1, "Failed to turn on VSS");

        if (!vdd_0p7_status)
            $fatal(1, "Failed to turn on VDD_0P7");

        if (!vdd_0p6_status)
            $fatal(1, "Failed to turn on VDD_0P6");

    end

endmodule
