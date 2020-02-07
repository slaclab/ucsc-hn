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

# Ethernet signals
set_property PACKAGE_PIN AA7  [get_ports ethRxP]
set_property PACKAGE_PIN AB7  [get_ports ethRxM]
set_property PACKAGE_PIN AA3  [get_ports ethTxP]
set_property PACKAGE_PIN AB3  [get_ports ethTxM]

# clk signals
set_property PACKAGE_PIN H4 [get_ports clockInP]
set_property PACKAGE_PIN H3 [get_ports clockInN]
set_property PACKAGE_PIN P3 [get_ports clockOutP]
set_property PACKAGE_PIN P2 [get_ports clockOutN]

# sync signals
set_property PACKAGE_PIN M2 [get_ports syncInP]
set_property PACKAGE_PIN M1 [get_ports syncInN]
set_property PACKAGE_PIN N1 [get_ports syncOutP]
set_property PACKAGE_PIN P1 [get_ports syncOutN]

# RX_BRD_XX signals (BANK 34 & 35)
set_property PACKAGE_PIN F5 [get_ports rdDataP[1]]
set_property PACKAGE_PIN E5 [get_ports rdDataN[1]]
set_property PACKAGE_PIN G3 [get_ports rdDataP[2]]
set_property PACKAGE_PIN G2 [get_ports rdDataN[2]]
set_property PACKAGE_PIN F2 [get_ports rdDataP[3]]
set_property PACKAGE_PIN F1 [get_ports rdDataN[3]]
set_property PACKAGE_PIN G4 [get_ports rdDataP[4]]
set_property PACKAGE_PIN F4 [get_ports rdDataN[4]]
set_property PACKAGE_PIN E4 [get_ports rdDataP[5]]
set_property PACKAGE_PIN E3 [get_ports rdDataN[5]]
set_property PACKAGE_PIN G6 [get_ports rdDataP[6]]
set_property PACKAGE_PIN F6 [get_ports rdDataN[6]]
set_property PACKAGE_PIN B2 [get_ports rdDataP[7]]
set_property PACKAGE_PIN B1 [get_ports rdDataN[7]]
set_property PACKAGE_PIN E8 [get_ports rdDataP[8]]
set_property PACKAGE_PIN D8 [get_ports rdDataN[8]]
set_property PACKAGE_PIN H1 [get_ports rdDataP[9]]
set_property PACKAGE_PIN G1 [get_ports rdDataN[9]]
set_property PACKAGE_PIN C6 [get_ports rdDataP[10]]
set_property PACKAGE_PIN C5 [get_ports rdDataN[10]]
set_property PACKAGE_PIN D5 [get_ports rdDataP[11]]
set_property PACKAGE_PIN C4 [get_ports rdDataN[11]]
set_property PACKAGE_PIN B4 [get_ports rdDataP[12]]
set_property PACKAGE_PIN B3 [get_ports rdDataN[12]]
set_property PACKAGE_PIN D3 [get_ports rdDataP[13]]
set_property PACKAGE_PIN C3 [get_ports rdDataN[13]]
set_property PACKAGE_PIN D1 [get_ports rdDataP[14]]
set_property PACKAGE_PIN C1 [get_ports rdDataN[14]]
set_property PACKAGE_PIN A2 [get_ports rdDataP[15]]
set_property PACKAGE_PIN A1 [get_ports rdDataN[15]]
set_property PACKAGE_PIN E2 [get_ports rdDataP[16]]
set_property PACKAGE_PIN D2 [get_ports rdDataN[16]]
set_property PACKAGE_PIN D7 [get_ports rdDataP[17]]
set_property PACKAGE_PIN D6 [get_ports rdDataN[17]]
set_property PACKAGE_PIN F7 [get_ports rdDataP[18]]
set_property PACKAGE_PIN E7 [get_ports rdDataN[18]]
set_property PACKAGE_PIN A5 [get_ports rdDataP[19]]
set_property PACKAGE_PIN A4 [get_ports rdDataN[19]]
set_property PACKAGE_PIN G8 [get_ports rdDataP[20]]
set_property PACKAGE_PIN G7 [get_ports rdDataN[20]]
set_property PACKAGE_PIN A7 [get_ports rdDataP[21]]
set_property PACKAGE_PIN A6 [get_ports rdDataN[21]]
set_property PACKAGE_PIN B7 [get_ports rdDataP[22]]
set_property PACKAGE_PIN B6 [get_ports rdDataN[22]]
set_property PACKAGE_PIN C8 [get_ports rdDataP[23]]
set_property PACKAGE_PIN B8 [get_ports rdDataN[23]]
set_property PACKAGE_PIN M4 [get_ports rdDataP[24]]
set_property PACKAGE_PIN M3 [get_ports rdDataN[24]]
set_property PACKAGE_PIN J2 [get_ports rdDataP[25]]
set_property PACKAGE_PIN J2 [get_ports rdDataN[25]]
set_property PACKAGE_PIN K7 [get_ports rdDataP[26]]
set_property PACKAGE_PIN L7 [get_ports rdDataN[26]]
set_property PACKAGE_PIN J3 [get_ports rdDataP[27]]
set_property PACKAGE_PIN K2 [get_ports rdDataN[27]]
set_property PACKAGE_PIN P7 [get_ports rdDataP[28]]
set_property PACKAGE_PIN R7 [get_ports rdDataN[28]]
set_property PACKAGE_PIN L2 [get_ports rdDataP[29]]
set_property PACKAGE_PIN L1 [get_ports rdDataN[29]]
set_property PACKAGE_PIN N4 [get_ports rdDataP[30]]
set_property PACKAGE_PIN N3 [get_ports rdDataN[30]]

#TX_BUFF_X (BANK 34)
set_property PACKAGE_PIN N6 [get_ports txData[1]]
set_property PACKAGE_PIN N5 [get_ports txData[2]]
set_property PACKAGE_PIN M8 [get_ports txData[3]]
set_property PACKAGE_PIN M7 [get_ports txData[4]]
set_property PACKAGE_PIN N8 [get_ports txData[5]]
set_property PACKAGE_PIN P8 [get_ports txData[6]]


set_property IOSTANDARD LVCMOS25 [get_ports i2cScl]
set_property IOSTANDARD LVCMOS25 [get_ports i2cSda]

#set_property IOSTANDARD LVCMOS25 [get_ports clkSelA]
#set_property IOSTANDARD LVCMOS25 [get_ports clkSelB]

#set_property IOSTANDARD LVCMOS25 [get_ports led]

#set_property IOSTANDARD LVDS_25 [get_ports dtmClkP]
#set_property IOSTANDARD LVDS_25 [get_ports dtmClkM]

#set_property IOSTANDARD LVDS_25 [get_ports dtmFbP]
#set_property IOSTANDARD LVDS_25 [get_ports dtmFbM]

####################
# Timing Constraints
####################

create_clock -name fclk0 -period 10.0 [get_pins {U_RceG3Top/GEN_SYNTH.U_RceG3Cpu/U_PS7/inst/PS7_i/FCLKCLK[0]}]

create_generated_clock -name clk200 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT0}]
create_generated_clock -name clk312 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name clk156 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT2}]
create_generated_clock -name clk125 [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT3}]
create_generated_clock -name clk62  [get_pins {U_RceG3Top/U_RceG3Clocks/U_MMCM/MmcmGen.U_Mmcm/CLKOUT4}]

create_generated_clock -name dnaClk  [get_pins {U_RceG3Top/GEN_SYNTH.U_RceG3AxiCntl/U_DeviceDna/GEN_7SERIES.DeviceDna7Series_Inst/BUFR_Inst/O}] 
create_generated_clock -name dnaClkL [get_pins {U_RceG3Top/GEN_SYNTH.U_RceG3AxiCntl/U_DeviceDna/GEN_7SERIES.DeviceDna7Series_Inst/DNA_CLK_INV_BUFR/O}] 
set_clock_groups -asynchronous -group [get_clocks {dnaClk}] -group [get_clocks {dnaClkL}] -group [get_clocks {clk125}] 

# Treat all clocks asynchronous to each-other except for clk62/clk125 (required by GEM/1000BASE-KX)    
set_clock_groups -asynchronous -group [get_clocks {clk62}]  -group [get_clocks {clk156}] -group [get_clocks {clk200}] -group [get_clocks {clk312}]   
set_clock_groups -asynchronous -group [get_clocks {clk125}] -group [get_clocks {clk156}] -group [get_clocks {clk200}] -group [get_clocks {clk312}]   

