#yosys -l my_synthesis.log
#yosys -l my_synthesis.log -c my_script.tcl
#yosys> tee -o timing_report.txt sta
#tee -o stat_cpu_core.log stat -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# https://skywater-pdk.readthedocs.io/en/main/contents/libraries/foundry-provided.html
#yosys> script ../scripts/synth.osoc1_cpu_core.tcl
#yosys -c ../scripts/synth.osoc1_cpu_core.tcl


# 1. Load the flattened Verilog file
# We reference the environment variable directly using the $::env syntax
#read_verilog ../src_sv2v/egs.v

read_verilog ../src_sv2v/osoc1_cpu_core.flat.v


# 2. Set the top-level module
hierarchy -check -top osoc1_cpu_core

# 3. Behavioral to Structural conversion
proc

# 4. Aggressive Global Optimization (DO THIS HERE)
# This cleans up the massive $mux structures created by the case statement
opt -full


# 2. Shatter memory arrays into discrete registers and multiplexers
memory
opt -full


# 5. Bit-blasting
techmap
#select -count c:*
#select -list p:*

opt_clean


# 6b. Sequential mapping to technology
dfflibmap -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 7. Final Cleanup (Standard sweep, not -full)
opt_clean

# 6. Logic Minimization and Mapping to Silicon
abc -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib -dont_use "*lpflow*" -dont_use "*clkbuf*" -dont_use "*clkinv*"

opt_clean


# Manually delete the metadata scope cells
#delete t:$scopeinfo

# Sweep away all floating wires, unused cells, and empty modules
#clean -purge

# 8. Report Area
stat -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 9. Write the clean, structural netlist
write_verilog -noattr -noexpr ../syn_netlist/osoc1_cpu_core.syn.sky130.vg


