#yosys -l my_synthesis.log
#yosys -l my_synthesis.log -c my_script.tcl
#yosys> tee -o timing_report.txt sta
#tee -o stat_cpu_core.log stat -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
# https://skywater-pdk.readthedocs.io/en/main/contents/libraries/foundry-provided.html
#yosys> script ../scripts/synth.osoc1_cpu_core.tcl
#yosys -c ../scripts/synth.osoc1_cpu_core.tcl


# 1. READ TIMING LIBRARIES (Including OpenRAM!)
# ------------------------------------------------------------------------------
# Read standard cell library
read_liberty -lib /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# CRITICAL: Read OpenRAM macro library. The '-lib' flag tells Yosys "Don't try to synthesize 
# this, just learn its pins and treat it as a black box."
read_liberty -lib /home/rashid/.volare/sky130A/libs.ref/sky130_sram_macros/lib/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib

# BOUNDS CHECK (Libraries):
# Min Libraries Loaded: 2 (1 Standard Cell, 1 SRAM Macro).
# Max Loading Errors: 0.

# 2. READ VERILOG DESIGN (Pre-flattened via sv2v)
# ------------------------------------------------------------------------------
# Read the single, flattened Verilog file. sv2v already handled the USE_OPENRAM defines!
read_verilog ../src_sv2v/osoc1_top.flat.v

# BOUNDS CHECK (read_verilog):
# Min Files Read: 1 (The flat file).
# Max Syntax Errors: 0.

# 3. HIERARCHY & SYNTHESIS
# ------------------------------------------------------------------------------
hierarchy -check -top osoc1_top

# BOUNDS CHECK (Hierarchy):
# Min Top-Level Modules: 1 (osoc1_top)
# Max Missing Modules: 0 (If Yosys complains about a missing module, it means the OpenRAM macro name in your wrapper doesn't match the .lib).

#synth -top osoc1_top

# Standard cell mapping
#dfflibmap -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
#abc -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib


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
#stat -liberty /home/rashid/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 9. Write the clean, structural netlist
#write_verilog -noattr -noexpr ../syn_netlist/osoc1_cpu_core.syn.sky130.vg

# 4. CLEANUP
# ------------------------------------------------------------------------------
# Clean up auto-generated instance names
rename -enumerate
opt_clean -purge

# 5. REPORTS & CHECKS
# ------------------------------------------------------------------------------
# Hunt down fatal design flaws (combinational loops, shorts, multi-driven nets)
check

# BOUNDS CHECK (check):
# Max Errors: 0 (If > 0, the netlist has broken logic).
# Max Warnings: < 20 (A few dangling unused wires are normal, but investigate large numbers).

# Dump a table of all used standard cells and macros
stat -top osoc1_top

# BOUNDS CHECK (stat):
# Min sky130_fd_sc_hd__df* (Flip-Flops): > 1000 (Confirms the CPU logic survived!).
# Max sky130_fd_sc_hd__df* (Flip-Flops): < 4000 (Ensures the SRAMs stayed as macros).
# Min sky130_sram_1kbyte* (Macros): 2 (Ensures the memories are intact).

# 6. EXPORT
# ------------------------------------------------------------------------------
write_verilog -noattr -noexpr -nohex ../syn_netlist/osoc1_top.syn.sky130.vg
