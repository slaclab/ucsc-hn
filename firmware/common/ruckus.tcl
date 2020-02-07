# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load local Source Code and constraints
loadSource -lib ucsc_hn -dir "$::DIR_PATH/rtl"

