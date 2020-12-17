##############################################################################
## This file is part of 'RCE Development Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'RCE Development Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

set_property PACKAGE_PIN AA16 [get_ports i2cScl]
set_property PACKAGE_PIN AA17 [get_ports i2cSda]

set_property IOSTANDARD LVCMOS [get_ports i2cScl]
set_property IOSTANDARD LVCMOS [get_ports i2cSda]

# Ethernet signals
set_property PACKAGE_PIN AA7  [get_ports ethRxP]
set_property PACKAGE_PIN AB7  [get_ports ethRxM]
set_property PACKAGE_PIN AA3  [get_ports ethTxP]
set_property PACKAGE_PIN AB3  [get_ports ethTxM]

# clk signals
#set_property PACKAGE_PIN U2 [get_ports clockInP]
#set_property PACKAGE_PIN U1 [get_ports clockInN]
set_property PACKAGE_PIN B7  [get_ports clockOutP]
set_property PACKAGE_PIN B6  [get_ports clockOutN]
set_property PACKAGE_PIN Y18 [get_ports clockHubInP]
set_property PACKAGE_PIN Y19 [get_ports clockHubInN]

#set_property IOSTANDARD LVDS [get_ports clockInP]
#set_property IOSTANDARD LVDS [get_ports clockInN]
set_property IOSTANDARD LVDS [get_ports clockOutP]
set_property IOSTANDARD LVDS [get_ports clockOutN]
set_property IOSTANDARD LVDS_18 [get_ports clockHubP]
set_property IOSTANDARD LVDS_18 [get_ports clockHubN]

# sync signals
#set_property PACKAGE_PIN V15 [get_ports syncPb]
set_property PACKAGE_PIN M4  [get_ports syncHubP]
set_property PACKAGE_PIN M3  [get_ports syncHubN]
set_property PACKAGE_PIN L6  [get_ports syncOutP]
set_property PACKAGE_PIN M6  [get_ports syncOutN]
set_property PACKAGE_PIN W15 [get_ports fpgaProgL]

#set_property IOSTANDARD LVCMOS [get_ports syncPb]
set_property IOSTANDARD LVDS [get_ports syncHubP]
set_property IOSTANDARD LVDS [get_ports syncHubN]
set_property IOSTANDARD LVDS [get_ports syncOutP]
set_property IOSTANDARD LVDS [get_ports syncOutN]
set_property IOSTANDARD LVCMOS [get_ports fpgaProgL]

# JTAG
#set_property PACKAGE_PIN Y14 [get_ports renaTdo]
#set_property PACKAGE_PIN Y15 [get_ports renaTdi]
#set_property PACKAGE_PIN V18 [get_ports renaTck]
#set_property PACKAGE_PIN W18 [get_ports renaTms]

# RX_BRD_XX
set_property PACKAGE_PIN F5 [get_ports rxDataP[1]]
set_property PACKAGE_PIN E5 [get_ports rxDataN[1]]
set_property PACKAGE_PIN F2 [get_ports rxDataP[2]]
set_property PACKAGE_PIN F1 [get_ports rxDataN[2]]
set_property PACKAGE_PIN E4 [get_ports rxDataP[3]]
set_property PACKAGE_PIN E3 [get_ports rxDataN[3]]
set_property PACKAGE_PIN B2 [get_ports rxDataP[4]]
set_property PACKAGE_PIN B1 [get_ports rxDataN[4]]
set_property PACKAGE_PIN H1 [get_ports rxDataP[5]]
set_property PACKAGE_PIN G1 [get_ports rxDataN[5]]
set_property PACKAGE_PIN D5 [get_ports rxDataP[6]]
set_property PACKAGE_PIN C4 [get_ports rxDataN[6]]
set_property PACKAGE_PIN D3 [get_ports rxDataP[7]]
set_property PACKAGE_PIN C3 [get_ports rxDataN[7]]
set_property PACKAGE_PIN A2 [get_ports rxDataP[8]]
set_property PACKAGE_PIN A1 [get_ports rxDataN[8]]
set_property PACKAGE_PIN D7 [get_ports rxDataP[9]]
set_property PACKAGE_PIN D6 [get_ports rxDataN[9]]
set_property PACKAGE_PIN A5 [get_ports rxDataP[10]]
set_property PACKAGE_PIN A4 [get_ports rxDataN[10]]
set_property PACKAGE_PIN A7 [get_ports rxDataP[11]]
set_property PACKAGE_PIN A6 [get_ports rxDataN[11]]
set_property PACKAGE_PIN C8 [get_ports rxDataP[12]]
set_property PACKAGE_PIN B8 [get_ports rxDataN[12]]
set_property PACKAGE_PIN G8 [get_ports rxDataP[13]]
set_property PACKAGE_PIN G7 [get_ports rxDataN[13]]
set_property PACKAGE_PIN F7 [get_ports rxDataP[14]]
set_property PACKAGE_PIN E7 [get_ports rxDataN[14]]
set_property PACKAGE_PIN E2 [get_ports rxDataP[15]]
set_property PACKAGE_PIN D2 [get_ports rxDataN[15]]
set_property PACKAGE_PIN D1 [get_ports rxDataP[16]]
set_property PACKAGE_PIN C1 [get_ports rxDataN[16]]
set_property PACKAGE_PIN B4 [get_ports rxDataP[17]]
set_property PACKAGE_PIN B3 [get_ports rxDataN[17]]
set_property PACKAGE_PIN C6 [get_ports rxDataP[18]]
set_property PACKAGE_PIN C5 [get_ports rxDataN[18]]
set_property PACKAGE_PIN E8 [get_ports rxDataP[19]]
set_property PACKAGE_PIN D8 [get_ports rxDataN[19]]
set_property PACKAGE_PIN G6 [get_ports rxDataP[20]]
set_property PACKAGE_PIN F6 [get_ports rxDataN[20]]
set_property PACKAGE_PIN G4 [get_ports rxDataP[21]]
set_property PACKAGE_PIN F4 [get_ports rxDataN[21]]
set_property PACKAGE_PIN G3 [get_ports rxDataP[22]]
set_property PACKAGE_PIN G2 [get_ports rxDataN[22]]
set_property PACKAGE_PIN H4 [get_ports rxDataP[23]]
set_property PACKAGE_PIN H3 [get_ports rxDataN[23]]
set_property PACKAGE_PIN J7 [get_ports rxDataP[24]]
set_property PACKAGE_PIN J6 [get_ports rxDataN[24]]
set_property PACKAGE_PIN J8 [get_ports rxDataP[25]]
set_property PACKAGE_PIN K8 [get_ports rxDataN[25]]
set_property PACKAGE_PIN M8 [get_ports rxDataP[26]]
set_property PACKAGE_PIN M7 [get_ports rxDataN[26]]
set_property PACKAGE_PIN N8 [get_ports rxDataP[27]]
set_property PACKAGE_PIN P8 [get_ports rxDataN[27]]
set_property PACKAGE_PIN N6 [get_ports rxDataP[28]]
set_property PACKAGE_PIN N5 [get_ports rxDataN[28]]
set_property PACKAGE_PIN P6 [get_ports rxDataP[29]]
set_property PACKAGE_PIN P5 [get_ports rxDataN[29]]
set_property PACKAGE_PIN R5 [get_ports rxDataP[30]]
set_property PACKAGE_PIN R4 [get_ports rxDataN[30]]

set_property IOSTANDARD LVDS [get_ports rxDataP[1]]
set_property IOSTANDARD LVDS [get_ports rxDataN[1]]
set_property IOSTANDARD LVDS [get_ports rxDataP[2]]
set_property IOSTANDARD LVDS [get_ports rxDataN[2]]
set_property IOSTANDARD LVDS [get_ports rxDataP[3]]
set_property IOSTANDARD LVDS [get_ports rxDataN[3]]
set_property IOSTANDARD LVDS [get_ports rxDataP[4]]
set_property IOSTANDARD LVDS [get_ports rxDataN[4]]
set_property IOSTANDARD LVDS [get_ports rxDataP[5]]
set_property IOSTANDARD LVDS [get_ports rxDataN[5]]
set_property IOSTANDARD LVDS [get_ports rxDataP[6]]
set_property IOSTANDARD LVDS [get_ports rxDataN[6]]
set_property IOSTANDARD LVDS [get_ports rxDataP[7]]
set_property IOSTANDARD LVDS [get_ports rxDataN[7]]
set_property IOSTANDARD LVDS [get_ports rxDataP[8]]
set_property IOSTANDARD LVDS [get_ports rxDataN[8]]
set_property IOSTANDARD LVDS [get_ports rxDataP[9]]
set_property IOSTANDARD LVDS [get_ports rxDataN[9]]
set_property IOSTANDARD LVDS [get_ports rxDataP[10]]
set_property IOSTANDARD LVDS [get_ports rxDataN[10]]
set_property IOSTANDARD LVDS [get_ports rxDataP[11]]
set_property IOSTANDARD LVDS [get_ports rxDataN[11]]
set_property IOSTANDARD LVDS [get_ports rxDataP[12]]
set_property IOSTANDARD LVDS [get_ports rxDataN[12]]
set_property IOSTANDARD LVDS [get_ports rxDataP[13]]
set_property IOSTANDARD LVDS [get_ports rxDataN[13]]
set_property IOSTANDARD LVDS [get_ports rxDataP[14]]
set_property IOSTANDARD LVDS [get_ports rxDataN[14]]
set_property IOSTANDARD LVDS [get_ports rxDataP[15]]
set_property IOSTANDARD LVDS [get_ports rxDataN[15]]
set_property IOSTANDARD LVDS [get_ports rxDataP[16]]
set_property IOSTANDARD LVDS [get_ports rxDataN[16]]
set_property IOSTANDARD LVDS [get_ports rxDataP[17]]
set_property IOSTANDARD LVDS [get_ports rxDataN[17]]
set_property IOSTANDARD LVDS [get_ports rxDataP[18]]
set_property IOSTANDARD LVDS [get_ports rxDataN[18]]
set_property IOSTANDARD LVDS [get_ports rxDataP[19]]
set_property IOSTANDARD LVDS [get_ports rxDataN[19]]
set_property IOSTANDARD LVDS [get_ports rxDataP[20]]
set_property IOSTANDARD LVDS [get_ports rxDataN[20]]
set_property IOSTANDARD LVDS [get_ports rxDataP[21]]
set_property IOSTANDARD LVDS [get_ports rxDataN[21]]
set_property IOSTANDARD LVDS [get_ports rxDataP[22]]
set_property IOSTANDARD LVDS [get_ports rxDataN[22]]
set_property IOSTANDARD LVDS [get_ports rxDataP[23]]
set_property IOSTANDARD LVDS [get_ports rxDataN[23]]
set_property IOSTANDARD LVDS [get_ports rxDataP[24]]
set_property IOSTANDARD LVDS [get_ports rxDataN[24]]
set_property IOSTANDARD LVDS [get_ports rxDataP[25]]
set_property IOSTANDARD LVDS [get_ports rxDataN[25]]
set_property IOSTANDARD LVDS [get_ports rxDataP[26]]
set_property IOSTANDARD LVDS [get_ports rxDataN[26]]
set_property IOSTANDARD LVDS [get_ports rxDataP[27]]
set_property IOSTANDARD LVDS [get_ports rxDataN[27]]
set_property IOSTANDARD LVDS [get_ports rxDataP[28]]
set_property IOSTANDARD LVDS [get_ports rxDataN[28]]
set_property IOSTANDARD LVDS [get_ports rxDataP[29]]
set_property IOSTANDARD LVDS [get_ports rxDataN[29]]
set_property IOSTANDARD LVDS [get_ports rxDataP[30]]
set_property IOSTANDARD LVDS [get_ports rxDataN[30]]

#TX_BUFF_X
set_property PACKAGE_PIN AB18 [get_ports txData[1]]
set_property PACKAGE_PIN AB19 [get_ports txData[2]]
set_property PACKAGE_PIN AA19 [get_ports txData[3]]
set_property PACKAGE_PIN AA20 [get_ports txData[4]]
set_property PACKAGE_PIN AB22 [get_ports txData[5]]
set_property PACKAGE_PIN AB21 [get_ports txData[6]]

set_property IOSTANDARD LVCMOS [get_ports txData[1]]
set_property IOSTANDARD LVCMOS [get_ports txData[2]]
set_property IOSTANDARD LVCMOS [get_ports txData[3]]
set_property IOSTANDARD LVCMOS [get_ports txData[4]]
set_property IOSTANDARD LVCMOS [get_ports txData[5]]
set_property IOSTANDARD LVCMOS [get_ports txData[6]]

set_property SLEW FAST [get_ports txData[1]]
set_property SLEW FAST [get_ports txData[2]]
set_property SLEW FAST [get_ports txData[3]]
set_property SLEW FAST [get_ports txData[4]]
set_property SLEW FAST [get_ports txData[5]]
set_property SLEW FAST [get_ports txData[6]]

####################
# Timing Constraints
####################

create_clock -name fclk0 -period 10.0 [get_pins {U_RceG3Top/GEN_SYNTH.U_RceG3Cpu/U_PS7/inst/PS7_i/FCLKCLK[0]}]

create_generated_clock -name clk200 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name clk312 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name clk156 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT2}]
create_generated_clock -name clk125 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT3}]
create_generated_clock -name clk62  [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT4}]

create_clock -name clockHubIn -period 20.0 [get_pins {U_FanInBoard/U_SlaveClockGen.U_ClockHubBuf/O}]
create_generated_clock -name rena50  [get_pins {U_FanInBoard/U_SlaveClockGen.U_RenaClkGen/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name rena200 [get_pins {U_FanInBoard/U_SlaveClockGen.U_RenaClkGen/MmcmGen.U_Mmcm/CLKOUT1}]

create_generated_clock -name dnaClk  [get_pins {U_RceG3Top/GEN_SYNTH.U_RceG3AxiCntl/U_DeviceDna/GEN_7SERIES.DeviceDna7Series_Inst/BUFR_Inst/O}]
create_generated_clock -name dnaClkL [get_pins {U_RceG3Top/GEN_SYNTH.U_RceG3AxiCntl/U_DeviceDna/GEN_7SERIES.DeviceDna7Series_Inst/DNA_CLK_INV_BUFR/O}]
set_clock_groups -asynchronous -group [get_clocks {dnaClk}] -group [get_clocks {dnaClkL}] -group [get_clocks {clk125}]

# Treat all clocks asynchronous to each-other except for clk62/clk125 (required by GEM/1000BASE-KX)
set_clock_groups -asynchronous -group [get_clocks {clk62}]  -group [get_clocks {clk156}] -group [get_clocks {clk200}] -group [get_clocks {clk312}]
set_clock_groups -asynchronous -group [get_clocks {clk125}] -group [get_clocks {clk156}] -group [get_clocks {clk200}] -group [get_clocks {clk312}]

set_clock_groups -asynchronous -group [get_clocks {rena200}] -group [get_clocks {clk156}] -group [get_clocks {clk200}]
set_clock_groups -asynchronous -group [get_clocks {rena50}]  -group [get_clocks {clk156}] -group [get_clocks {clk200}]
set_clock_groups -asynchronous -group [get_clocks {rena200}] -group [get_clocks {clk125}]
set_clock_groups -asynchronous -group [get_clocks {rena200}] -group [get_clocks {clk62}]
set_clock_groups -asynchronous -group [get_clocks {rena50}]  -group [get_clocks {clk125}]
set_clock_groups -asynchronous -group [get_clocks {rena50}]  -group [get_clocks {clk62}]

