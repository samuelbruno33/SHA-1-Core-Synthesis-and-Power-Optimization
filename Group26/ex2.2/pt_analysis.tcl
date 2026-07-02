##	+----------------------------------------------------------------
##	|		 Synthesis and Optimization of Digital Systems			|
##	|				Politecnico di Torino - TO - Italy				|
##	|						DAUIN - EDA GROUP						|
##	+----------------------------------------------------------------
##	|	author: Valentino Peluso									|
##	|	mail:	valentino.peluso@polito.it							|
##	|	title:	pt_analysis.tcl										|
##	+----------------------------------------------------------------
##	| 	Copyright 2026 DAUIN - EDA GROUP							|
##	+----------------------------------------------------------------

######################################################################
##
## SPECIFY LIBRARIES
##
######################################################################

# SOURCE SETUP FILE
source "./Group26/ex2.2/synopsys_pt.setup"

# DEFINE OPTIONS
set report_default_significant_digits 6
set power_enable_analysis true

# SUPPRESS WARNING MESSAGES
suppress_message RC-004
suppress_message PTE-003
suppress_message UID-401
suppress_message ENV-003
suppress_message UITE-489
suppress_message CMD-041
suppress_message PLIB-166
suppress_message PLIB-167
suppress_message PTE-139
suppress_message NED-045

######################################################################
##
## READ DESIGN
##
######################################################################
# DEFINE CIRCUITS
set blockName "sha1_core"

# DEFINE INPUT FILES
set dir "./saved/${blockName}/synthesis"
set in_verilog_filename "${dir}/${blockName}_postsyn.v"
set in_sdc_filename "${dir}/${blockName}_postsyn.sdc"

# READ
read_verilog $in_verilog_filename
link_design $blockName
read_sdc $in_sdc_filename
set_ideal_network "clk"
set_ideal_network "reset_n"

update_timing -full

######################################################################
##
## TIMING ANALYSIS
##
######################################################################
# SETUP TIME
report_timing -delay_type max

# SLACK CONDITION
report_timing -delay_type min -slack_lesser_than 0.1 -max_paths 2
report_timing -delay_type max -slack_lesser_than 0.0 -max_paths 2

######################################################################
##
## POWER ANALYSIS (VCD-BASED SWA BACK-ANNOTATION)
##
######################################################################

set vcd_file "./saved/${blockName}/simulation/${blockName}.vcd"

# Read VCD file and strip the testbench hierarchy to match the top-level design
read_vcd $vcd_file -strip_path "tb_sha1_core/dut" -zero_delay

set_power_clock_scaling -period [get_attribute [get_clocks] period] [get_clocks]
set power_enable_clock_scaling true

update_power
report_power

######################################################################
## EXTRACT AND REPORT METRICS
######################################################################
set clockPeriod [get_attribute [get_clocks] period]
set wrt_slack [get_attribute [get_timing_paths] slack]
set area [get_attribute [current_design] area]

set dynamic_w [get_attribute [current_design] dynamic_power]
set leakage_w [get_attribute [current_design] leakage_power]
set dynamic_mw [expr {$dynamic_w * 1000.0}]
set leakage_mw [expr {$leakage_w * 1000.0}]

# Get Gates and Count VT percentages
set gates [get_cells -hierarchical -filter "is_hierarchical == false"]
set total_gates [sizeof_collection $gates]
set lvt_gates [sizeof_collection [filter_collection $gates "ref_name =~ *LL*"]]
set svt_gates [sizeof_collection [filter_collection $gates "ref_name =~ *LS*"]]
set hvt_gates [sizeof_collection [filter_collection $gates "ref_name =~ *LH*"]]

set perc_lvt [expr {100.0 * $lvt_gates / $total_gates}]
set perc_svt [expr {100.0 * $svt_gates / $total_gates}]
set perc_hvt [expr {100.0 * $hvt_gates / $total_gates}]

puts "\n========================================================"
puts "         EXERCISE 2.2 - CLOCK GATING & MULTI-VT REPORT"
puts "========================================================"
puts "Percentage of LVT cells (%): $perc_lvt"
puts "Percentage of SVT cells (%): $perc_svt"
puts "Percentage of HVT cells (%): $perc_hvt"
puts "Area (um2)                 : $area"
puts "Slack (ns)                 : $wrt_slack"
puts "Leakage power (mW)         : $leakage_mw"
puts "Dynamic power (mW)         : $dynamic_mw"
puts "========================================================\n"

######################################################################
##
## EXIT
##
######################################################################
exit