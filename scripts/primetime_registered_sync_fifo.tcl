set script_dir [file dirname [file normalize [info script]]]
set project_root [file normalize [file join $script_dir ..]]

puts "PrimeTime project root: $project_root"

set netlist_file [file join $project_root netlist registered_sync_fifo_gated.v]
set sdc_file [file join $project_root netlist registered_sync_fifo_gated.sdc]
set upf_file [file join $project_root netlist registered_sync_fifo_gated.upf]
set saif_file [file join $project_root saif registered_sync_fifo.saif]
set library_dir [file join $project_root lib asap7_db]
set report_dir [file join $project_root reports power]

foreach required_file [list $netlist_file $sdc_file $upf_file $saif_file] {
    if {![file readable $required_file]} {
        error "Cannot read required file: $required_file"
    }
}

file mkdir $report_dir

set_app_var power_enable_analysis true
set_app_var power_analysis_mode averaged

set_app_var search_path [concat $search_path [list $library_dir [file join $project_root netlist]]]
set_app_var link_path [list \
    "*" \
    [file join $library_dir asap7sc7p5t_AO_RVT_TT_08302018.db] \
    [file join $library_dir asap7sc7p5t_INVBUF_RVT_TT_08302018.db] \
    [file join $library_dir asap7sc7p5t_OA_RVT_TT_08302018.db] \
    [file join $library_dir asap7sc7p5t_SEQ_RVT_TT_08302018.db] \
    [file join $library_dir asap7sc7p5t_SIMPLE_RVT_TT_08302018.db] \
]

read_verilog $netlist_file
link_design registered_sync_fifo
current_design registered_sync_fifo
load_upf $upf_file
read_sdc $sdc_file

redirect -file [file join $report_dir registered_sync_fifo_design.rpt] { report_design }
redirect -file [file join $report_dir registered_sync_fifo_check_mv.rpt] { check_mv_design }
redirect -file [file join $report_dir registered_sync_fifo_check_timing.rpt] { check_timing }
redirect -file [file join $report_dir registered_sync_fifo_units.rpt] { report_units }

read_saif -strip_path registered_sync_fifo_tb/dut $saif_file
redirect -file [file join $report_dir registered_sync_fifo_activity.rpt] { report_switching_activity }

update_timing

redirect -file [file join $report_dir registered_sync_fifo_qor.rpt] { report_qor }
redirect -file [file join $report_dir registered_sync_fifo_setup.rpt] {
    report_timing -path_type full -delay_type max -max_paths 10 -sort_by slack
}
redirect -file [file join $report_dir registered_sync_fifo_hold.rpt] {
    report_timing -path_type full -delay_type min -max_paths 10 -sort_by slack
}
redirect -file [file join $report_dir registered_sync_fifo_all_hold_violations.rpt] {
    report_timing -path_type full -delay_type min -slack_lesser_than 0.0 -max_paths 300 -sort_by slack
}
redirect -file [file join $report_dir registered_sync_fifo_analysis_coverage.rpt] {
    report_analysis_coverage
}
redirect -file [file join $report_dir registered_sync_fifo_check_power.rpt] { check_power }

update_power

redirect -file [file join $report_dir registered_sync_fifo_power.rpt] { report_power -hierarchy }
redirect -file [file join $report_dir registered_sync_fifo_power_verbose.rpt] { report_power -verbose }

exit
