------------------------------------------------------------------------------
-- This file is part of 'RCE Development Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'RCE Development Firmware', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- DefaultBoot.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

entity DefaultBoot is
   generic (
      BUILD_INFO_G    : BuildInfoType);
   port (

      -- I2C
      i2cSda      : inout sl;
      i2cScl      : inout sl;

      -- Ethernet
      ethRxP      : in    sl;
      ethRxN      : in    sl;
      ethTxP      : out   sl;
      ethTxN      : out   sl;

      -- Rena fan in board clocks
      clockInP    : in    sl;
      clockInN    : in    sl;
      clockOutP   : out   sl;
      clockOutN   : out   sl;

      -- Sync signals
      syncInP     : in    sl;
      syncInN     : in    sl;
      syncOutP    : out   sl;
      syncOutN    : out   sl;

      -- Data inputs
      rxDataP     : in    slv(30 downto 1);
      rxDataN     : in    slv(30 downto 1);

      -- Control outputs
      txData      : out   slv(6  downto 1)
   );
end DefaultBoot;

architecture STRUCTURE of DefaultBoot is

   constant TPD_C : time := 1 ns;

   signal stableClk : sl;
   signal stableRst : sl;
   signal clk312    : sl;
   signal rst312    : sl;
   signal clk200    : sl;
   signal rst200    : sl;
   signal clk156    : sl;
   signal rst156    : sl;
   signal clk125    : sl;
   signal rst125    : sl;
   signal clk62     : sl;
   signal rst62     : sl;
   signal locked    : sl;
   signal axiDmaClk : sl;
   signal axiDmaRst : sl;
   signal axilClk   : sl;
   signal axilRst   : sl;

   -- External Axi Bus, 0xA0000000 - 0xAFFFFFFF  (axilClk domain)
   signal extAxilReadMaster  : AxiLiteReadMasterType;
   signal extAxilReadSlave   : AxiLiteReadSlaveType;
   signal extAxilWriteMaster : AxiLiteWriteMasterType;
   signal extAxilWriteSlave  : AxiLiteWriteSlaveType;

   -- Core Axi Bus, 0xB0000000 - 0xBFFFFFFF  (axilClk domain)
   signal coreAxilReadMaster  : AxiLiteReadMasterType;
   signal coreAxilReadSlave   : AxiLiteReadSlaveType;
   signal coreAxilWriteMaster : AxiLiteWriteMasterType;
   signal coreAxilWriteSlave  : AxiLiteWriteSlaveType;

   -- DMA Interfaces (dmaClk domain)
   signal dmaClk      : slv(3 downto 0);
   signal dmaClkRst   : slv(3 downto 0);
   signal dmaState    : RceDmaStateArray(3 downto 0);
   signal dmaObMaster : AxiStreamMasterArray(3 downto 0);
   signal dmaObSlave  : AxiStreamSlaveArray(3 downto 0);
   signal dmaIbMaster : AxiStreamMasterArray(3 downto 0);
   signal dmaIbSlave  : AxiStreamSlaveArray(3 downto 0);

   -- ZYNQ GEM Interface
   signal armEthTx   : ArmEthTxArray(1 downto 0);
   signal armEthRx   : ArmEthRxArray(1 downto 0);
   signal armEthMode : slv(31 downto 0);

begin


   --------------------------------------------------
   -- RCE Core
   --------------------------------------------------
   U_RceG3Top : entity rce_gen3_fw_lib.RceG3Top
      generic map (
         TPD_G              => TPD_C,
         MEMORY_TYPE_G      => "block",
         SEL_REFCLK_G       => false,
         BUILD_INFO_G       => BUILD_INFO_G,
         SLOW_PLL_G         => true,
         PCIE_EN_G          => false,
         RCE_DMA_MODE_G     => RCE_DMA_AXISV2_C)
      port map (
         -- I2C Ports
         i2cSda              => i2cSda,
         i2cScl              => i2cScl,
         -- Reference Clock
         ethRefClkP          => '0',
         ethRefClkN          => '1',
         ethRefClk           => open,
         stableClk           => stableClk,
         stableRst           => stableRst,
         -- Top-level clocks and resets
         clk312              => clk312,
         rst312              => rst312,
         clk200              => clk200,
         rst200              => rst200,
         clk156              => clk156,
         rst156              => rst156,
         clk125              => clk125,
         rst125              => rst125,
         clk62               => clk62,
         rst62               => rst62,
         locked              => locked,
         userInterrupt       => (others=>'0'),
         -- DMA clock and reset
         axiDmaClk           => axiDmaClk,
         axiDmaRst           => axiDmaRst,
         -- AXI-Lite clock and reset
         axilClk             => axilClk,
         axilRst             => axilRst,
         -- External Axi Bus, (axilClk domain)
         -- 0xA0000000 - 0xAFFFFFFF (COB_MIN_C10_G = False)
         -- 0x90000000 - 0x97FFFFFF (COB_MIN_C10_G = True)         
         extAxilReadMaster   => extAxilReadMaster,
         extAxilReadSlave    => extAxilReadSlave,
         extAxilWriteMaster  => extAxilWriteMaster,
         extAxilWriteSlave   => extAxilWriteSlave,
         -- Core Axi Bus, 0xB0000000 - 0xBFFFFFFF  (axilClk domain)
         coreAxilReadMaster  => coreAxilReadMaster,
         coreAxilReadSlave   => coreAxilReadSlave,
         coreAxilWriteMaster => coreAxilWriteMaster,
         coreAxilWriteSlave  => coreAxilWriteSlave,
         -- DMA Interfaces (dmaClk domain)
         dmaClk              => dmaClk,
         dmaClkRst           => dmaClkRst,
         dmaState            => dmaState,
         dmaObMaster         => dmaObMaster,
         dmaObSlave          => dmaObSlave,
         dmaIbMaster         => dmaIbMaster,
         dmaIbSlave          => dmaIbSlave,
         -- ZYNQ GEM Interface
         armEthTx            => armEthTx,
         armEthRx            => armEthRx,
         armEthMode          => armEthMode);


   -- GEM Boot
   U_RceEthGem : entity rce_gen3_fw_lib.RceEthGem
      generic map (
         TPD_G => TPD_C)
      port map (
         sysClk125 => clk125,
         sysRst125 => rst125,
         sysClk62  => clk62,
         sysRst62  => rst62,
         locked    => locked,
         stableClk => stableClk,
         stableRst => stableRst,
         -- ARM Interface
         armEthTx  => armEthTx(0),
         armEthRx  => armEthRx(0),
         -- Ethernet Lines
         gtRxP     => ethRxP,
         gtRxN     => ethRxN,
         gtTxP     => ethTxP,
         gtTxN     => ethTxN);

   armEthMode <= x"00000001";

   --coreAxilReadMaster   : AxiLiteReadMasterType;
   coreAxilReadSlave    <= AXI_LITE_READ_SLAVE_INIT_C;
   --coreAxilWriteMaster  : AxiLiteWriteMasterType;
   coreAxilWriteSlave   <= AXI_LITE_WRITE_SLAVE_INIT_C;

   --extAxilReadMaster   : AxiLiteReadMasterType;
   extAxilReadSlave    <= AXI_LITE_READ_SLAVE_INIT_C;
   --extAxilWriteMaster  : AxiLiteWriteMasterType;
   extAxilWriteSlave   <= AXI_LITE_WRITE_SLAVE_INIT_C;

   dmaClk <= (others=>axiDmaClk);
   dmaClkRst <= (others=>axiDmaRst);

   dmaObSlave  <= dmaIbSlave;
   dmaIbMaster <= dmaObMaster;

end architecture STRUCTURE;

