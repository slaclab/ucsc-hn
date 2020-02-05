##############################################################################
## This file is part of 'RCE Development Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'RCE Development Firmware', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

## Open the run
open_run synth_1

## Create core
set ilaName u_ila_0
CreateDebugCore ${ilaName}

## Configure Core
set_property C_DATA_DEPTH            1024 [get_debug_cores ${ilaName}]
#set_property C_ADV_TRIGGER           true [get_debug_cores ${ilaName}]
#set_property C_EN_STRG_QUAL          true [get_debug_cores ${ilaName}]
set_property C_INPUT_PIPE_STAGES     2    [get_debug_cores ${ilaName}]
#set_property ALL_PROBE_SAME_MU_CNT   4    [get_debug_cores ${ilaName}]

## Setup Clock, Variable set in xdc file
SetDebugCoreClk ${ilaName} [get_nets -of_objects ${dmaClkGroup}]

ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/axiWriteToCntrl[avalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/axiWriteToCntrl[length]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/axiWriteToCntrl[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/axiWriteToCntrl[dvalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/axiWriteToCntrl[dstrobe]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/axiWriteToCntrl[last]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/ibPpiFifo[eof]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/ibPpiFifo[valid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/ibPpiFifo[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/ibPpiFifoRead}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[0].U_IbDma/duplicate}

ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/axiWriteToCntrl[avalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/axiWriteToCntrl[length]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/axiWriteToCntrl[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/axiWriteToCntrl[dvalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/axiWriteToCntrl[dstrobe]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/axiWriteToCntrl[last]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/ibPpiFifo[eof]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/ibPpiFifo[valid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/ibPpiFifo[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/ibPpiFifoRead}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[1].U_IbDma/duplicate}

ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/axiWriteToCntrl[avalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/axiWriteToCntrl[length]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/axiWriteToCntrl[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/axiWriteToCntrl[dvalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/axiWriteToCntrl[dstrobe]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/axiWriteToCntrl[last]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/ibPpiFifo[eof]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/ibPpiFifo[valid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/ibPpiFifo[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/ibPpiFifoRead}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/duplicate}

ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/axiWriteToCntrl[avalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/axiWriteToCntrl[length]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/axiWriteToCntrl[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/axiWriteToCntrl[dvalid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/axiWriteToCntrl[dstrobe]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/axiWriteToCntrl[last]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/ibPpiFifo[eof]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/ibPpiFifo[valid]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/ibPpiFifo[data]*}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[2].U_IbDma/ibPpiFifoRead}
ConfigProbe ${ilaName} {U_DtmCore/U_ArmRceG3Top/U_ArmRceG3DmaCntrl/U_IbDmaGen[3].U_IbDma/duplicate}


## Delete the last unused port
delete_debug_port [get_debug_ports [GetCurrentProbe ${ilaName}]]

## Write the port map file
write_debug_probes -force ${PROJ_DIR}/debug/debug_probes.ltx

