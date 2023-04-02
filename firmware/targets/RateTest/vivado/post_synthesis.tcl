##############################################################################
## This file is part of 'ATLAS RD53 DEV'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'ATLAS RD53 DEV', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

##############################
# Get variables and procedures
##############################
source -quiet $::env(RUCKUS_DIR)/vivado/env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado/proc.tcl

# Bypass the debug chipscope generation
return

############################
## Open the synthesis design
############################
open_run synth_1

############################
## Get a list of nets
############################
set netFile ${PROJ_DIR}/net_log.txt
set fd [open ${netFile} "w"]
set nl ""

append nl [get_nets {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/*}]
append nl [get_nets {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/*}]

regsub -all -line { } $nl "\n" nl
puts $fd $nl
close $fd

###############################
## Set the name of the ILA core
###############################
set ilaName u_ila_1

##################
## Create the core
##################
CreateDebugCore ${ilaName}

#######################
## Set the record depth
#######################
set_property C_DATA_DEPTH 4096 [get_debug_cores ${ilaName}]

#################################
## Set the clock for the ILA core
#################################
SetDebugCoreClk ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/clk}

#######################
## Set the debug Probes
#######################

ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/r_reg[clkEnCount][*]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/r_reg[rxShiftCount][*]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/r_reg[rxShiftReg][*]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/r_reg[rxState_n_0_][*]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/r_reg[waitState_n_0_][*]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/rdData[*]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/rdValid}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/rst}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/rx}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/rxFall}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/rxSync}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/v[rdData]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/U_UartRx/v[rxState]}
ConfigProbe ${ilaName} {U_FanInBoard/U_DeserializerGen[1].U_Deserializer/r_reg[dropCntEn_n_0_]}

##########################
## Write the port map file
##########################
WriteDebugProbes ${ilaName}

