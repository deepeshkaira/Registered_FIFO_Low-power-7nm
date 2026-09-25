set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]
cd $project_root

set_app_var search_path [concat $search_path [list ./rtl ./constraints ./upf ./lib/asap7_db]]

set_app_var target_library [list \
    asap7sc7p5t_AO_RVT_TT_08302018.db \
    asap7sc7p5t_INVBUF_RVT_TT_08302018.db \
    asap7sc7p5t_OA_RVT_TT_08302018.db \
    asap7sc7p5t_SEQ_RVT_TT_08302018.db \
    asap7sc7p5t_SIMPLE_RVT_TT_08302018.db \
]

set_app_var link_library [concat "*" $target_library]

file mkdir work
file mkdir netlist
file mkdir reports
file mkdir reports/synthesis

define_design_lib WORK -path ./work

analyze -format sverilog [list \
    rtl/gated_clk.sv \
    rtl/fifo_input_register.sv \
    rtl/sync_fifo.sv \
    rtl/registered_sync_fifo.sv \
]

elaborate registered_sync_fifo
current_design registered_sync_fifo
link
uniquify

redirect -file reports/synthesis/registered_sync_fifo_check_design_precompile.rpt {
    check_design
}

load_upf upf/registered_sync_fifo.upf
read_sdc constraints/registered_sync_fifo.sdc

redirect -file reports/synthesis/registered_sync_fifo_check_mv_precompile.rpt {
    check_mv_design
}

compile_ultra

set_fix_multiple_port_nets -all -buffer_constants
change_names -rules verilog -hierarchy

redirect -file reports/synthesis/registered_sync_fifo_check_design_postcompile.rpt {
    check_design
}

redirect -file reports/synthesis/registered_sync_fifo_check_mv_postcompile.rpt {
    check_mv_design
}

redirect -file reports/synthesis/registered_sync_fifo_qor.rpt {
    report_qor
}

redirect -file reports/synthesis/registered_sync_fifo_area.rpt {
    report_area -hierarchy
}

redirect -file reports/synthesis/registered_sync_fifo_setup.rpt {
    report_timing -delay_type max -max_paths 10
}

redirect -file reports/synthesis/registered_sync_fifo_hold.rpt {
    report_timing -delay_type min -max_paths 10
}

redirect -file reports/synthesis/registered_sync_fifo_power_estimate.rpt {
    report_power -hierarchy
}

redirect -file reports/synthesis/registered_sync_fifo_references.rpt {
    report_reference -hierarchy
}

write -format ddc -hierarchy -output netlist/registered_sync_fifo_gated.ddc
write -format verilog -hierarchy -output netlist/registered_sync_fifo_gated.v
write_sdc netlist/registered_sync_fifo_gated.sdc
save_upf netlist/registered_sync_fifo_gated.upf

exit
