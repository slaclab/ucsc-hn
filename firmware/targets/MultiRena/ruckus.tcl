# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/RceG3
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/RceEthernet
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/PpiCommon
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/PpiPgp

# Load local Source Code and constraints
loadSource -dir       "$::DIR_PATH/hdl/"
loadConstraints -dir  "$::DIR_PATH/hdl/"
