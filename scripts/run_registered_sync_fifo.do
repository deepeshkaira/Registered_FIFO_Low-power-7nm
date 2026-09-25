onerror {quit -code 1}

set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
cd $project_root

file mkdir work
file mkdir reports
file mkdir reports/saif

vlib work
vmap work work

vlog -sv -L mtiUPF +incdir+./rtl +incdir+./tb \
    ./rtl/gated_clk.sv \
    ./rtl/fifo_input_register.sv \
    ./rtl/sync_fifo.sv \
    ./rtl/registered_sync_fifo.sv \
    ./tb/registered_sync_fifo_tb.sv

vopt registered_sync_fifo_tb \
    +acc \
    -pa_top /registered_sync_fifo_tb/dut \
    -pa_upf ./upf/registered_sync_fifo.upf \
    -pa_upfversion=2.1 \
    -pa_checks=sl+si \
    -pa_lib work \
    -pa_genrpt=pa+de \
    -o registered_sync_fifo_tb_pa_opt

vsim -sv_seed 12345 registered_sync_fifo_tb_pa_opt -pa -pa_lib work

add wave sim:/registered_sync_fifo_tb/clk
add wave sim:/registered_sync_fifo_tb/vif/rst_n
add wave sim:/registered_sync_fifo_tb/vif/en_i
add wave sim:/registered_sync_fifo_tb/vif/data_i
add wave sim:/registered_sync_fifo_tb/vif/data_valid_i
add wave sim:/registered_sync_fifo_tb/vif/rd_en_i
add wave sim:/registered_sync_fifo_tb/vif/read_data_o
add wave sim:/registered_sync_fifo_tb/vif/fifo_full_o
add wave sim:/registered_sync_fifo_tb/vif/fifo_empty_o
add wave sim:/registered_sync_fifo_tb/vif/pd1_power_on_i
add wave sim:/registered_sync_fifo_tb/vif/pd1_isolation_i
add wave sim:/registered_sync_fifo_tb/dut/u_input_register/data_q
add wave sim:/registered_sync_fifo_tb/dut/u_input_register/valid_q
add wave sim:/registered_sync_fifo_tb/dut/u_input_register/input_accept
add wave sim:/registered_sync_fifo_tb/dut/u_input_register/fifo_accept
add wave sim:/registered_sync_fifo_tb/dut/u_fifo/gated_write_clk
add wave sim:/registered_sync_fifo_tb/dut/u_fifo/gated_read_clk
add wave sim:/registered_sync_fifo_tb/dut/u_fifo/write_pointer
add wave sim:/registered_sync_fifo_tb/dut/u_fifo/read_pointer
add wave sim:/registered_sync_fifo_tb/dut/u_fifo/fifo_full_next
add wave sim:/registered_sync_fifo_tb/dut/u_fifo/fifo_empty_next
add wave sim:/registered_sync_fifo_tb/dut/u_fifo/read_data_q
add wave -r sim:/registered_sync_fifo_tb/dut/u_fifo/fifo_mem

# Reset is released before the first functional transaction. Begin collection at 46 ns.
run 46ns
power add -r /registered_sync_fifo_tb/dut/*
run -all
power report -all -bsaif reports/saif/registered_sync_fifo.saif
pa report -scope=/registered_sync_fifo_tb/dut
