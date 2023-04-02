# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

#set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/surf
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/RceG3
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/RceEthernet
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/PpiCommon
loadRuckusTcl $::env(PROJ_DIR)/../../submodules/rce-gen3-fw-lib/PpiPgp
loadRuckusTcl $::env(PROJ_DIR)/../../common

# Load local Source Code and constraints
loadSource -dir       "$::DIR_PATH/hdl/"
loadConstraints -dir  "$::DIR_PATH/hdl/"
