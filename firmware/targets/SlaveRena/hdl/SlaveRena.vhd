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
-- SlaveRena.vhd
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
use surf.EthMacPkg.all;

library ucsc_hn;

entity SlaveRena is
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

      -- Hub clock and sync
      clockHubP : in    sl;
      clockHubN : in    sl;
      syncHubP  : inout sl;
      syncHubN  : inout sl;

      -- Rena Clock And Sync
      clockOutP   : out   sl;
      clockOutN   : out   sl;
      syncOutP    : out   sl;
      syncOutN    : out   sl;
      fpgaProgL   : out   sl;

      -- Data inputs
      rxDataP     : in    slv(30 downto 1);
      rxDataN     : in    slv(30 downto 1);

      -- Control outputs
      txData      : out   slv(6  downto 1)
   );
end SlaveRena;

architecture STRUCTURE of SlaveRena is

   constant TPD_C : time := 1 ns;

   constant SERVER_PORTS_C : PositiveArray(1 downto 0) := (
      1 => 2542,   -- Xilinx XVC
      0 => 8192);

   constant APP_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C     => False,
      TDATA_BYTES_C  => 8,
      TDEST_BITS_C   => 0,
      TID_BITS_C     => 0,
      TKEEP_MODE_C   => TKEEP_COMP_C,
      TUSER_BITS_C   => 2,
      TUSER_MODE_C   => TUSER_FIRST_LAST_C);

   -- AXI-Lite
   constant AXIL_XBAR_MASTERS_C : integer := 3;
   constant MAC_AXIL_INDEX_C    : integer := 0;
   constant UDP_AXIL_INDEX_C    : integer := 1;
   constant RSSI_AXIL_INDEX_C   : integer := 2;

   constant AXIL_XBAR_CFG_C : AxiLiteCrossbarMasterConfigArray(AXIL_XBAR_MASTERS_C-1 downto 0) := (
      MAC_AXIL_INDEX_C  => (
         baseAddr       => X"B0000000",
         addrBits       => 16,
         connectivity   => X"FFFF"),
      UDP_AXIL_INDEX_C  => (
         baseAddr       => X"B0010000",
         addrBits       => 16,
         connectivity   => X"FFFF"),
      RSSI_AXIL_INDEX_C => (
         baseAddr       => X"B0020000",
         addrBits       => 10,
         connectivity   => X"FFFF"));

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

   -- Core Axi Bus, 0xB0000000 - 0xBFFFFFFF  (axilClk domain)
   signal coreAxilReadMasters  : AxiLiteReadMasterArray(AXIL_XBAR_MASTERS_C-1 downto 0);
   signal coreAxilReadSlaves   : AxiLiteReadSlaveArray(AXIL_XBAR_MASTERS_C-1 downto 0);
   signal coreAxilWriteMasters : AxiLiteWriteMasterArray(AXIL_XBAR_MASTERS_C-1 downto 0);
   signal coreAxilWriteSlaves  : AxiLiteWriteSlaveArray(AXIL_XBAR_MASTERS_C-1 downto 0);

   signal udpAxilReadMaster  : AxiLiteReadMasterType;
   signal udpAxilReadSlave   : AxiLiteReadSlaveType;
   signal udpAxilWriteMaster : AxiLiteWriteMasterType;
   signal udpAxilWriteSlave  : AxiLiteWriteSlaveType;

   signal udpObServerMasters : AxiStreamMasterArray(1 downto 0);
   signal udpObServerSlaves  : AxiStreamSlaveArray(1 downto 0);
   signal udpIbServerMasters : AxiStreamMasterArray(1 downto 0);
   signal udpIbServerSlaves  : AxiStreamSlaveArray(1 downto 0);

   -- DMA Interfaces (dmaClk domain)
   signal dmaClk      : slv(3 downto 0);
   signal dmaClkRst   : slv(3 downto 0);
   signal dmaState    : RceDmaStateArray(3 downto 0);
   signal dmaObMaster : AxiStreamMasterArray(3 downto 0);
   signal dmaObSlave  : AxiStreamSlaveArray(3 downto 0);
   signal dmaIbMaster : AxiStreamMasterArray(3 downto 0);
   signal dmaIbSlave  : AxiStreamSlaveArray(3 downto 0);

   -- User Ethernet
   signal userEthClk           : sl;
   signal userEthClkRst        : sl;
   signal userEthUdpIbMaster   : AxiStreamMasterType;
   signal userEthUdpIbSlave    : AxiStreamSlaveType;
   signal userEthUdpObMaster   : AxiStreamMasterType;
   signal userEthUdpObSlave    : AxiStreamSlaveType;
   signal localIp              : slv(31 downto 0);
   signal localMac             : slv(47 downto 0);

   signal rssiObMaster    : AxiStreamMasterType;
   signal rssiObSlave     : AxiStreamSlaveType;
   signal rssiIbMaster    : AxiStreamMasterType;
   signal rssiIbSlave     : AxiStreamSlaveType;

   -- ZYNQ GEM Interface
   signal armEthTx   : ArmEthTxArray(1 downto 0);
   signal armEthRx   : ArmEthRxArray(1 downto 0);
   signal armEthMode : slv(31 downto 0);

   signal iethRxP : slv(3 downto 0);
   signal iethRxN : slv(3 downto 0);
   signal iethTxP : slv(3 downto 0);
   signal iethTxN : slv(3 downto 0);

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
         ethRefClkP          => '1',
         ethRefClkN          => '0',
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

   ----------------------------------------------------------------------------
   --                         Core AXI Crossbar                              --
   ----------------------------------------------------------------------------
   U_AxiLiteCrossbar_1 : entity surf.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_C,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => AXIL_XBAR_MASTERS_C,
         MASTERS_CONFIG_G   => AXIL_XBAR_CFG_C,
         DEBUG_G            => false)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => coreAxilWriteMaster,
         sAxiWriteSlaves(0)  => coreAxilWriteSlave,
         sAxiReadMasters(0)  => coreAxilReadMaster,
         sAxiReadSlaves(0)   => coreAxilReadSlave,
         mAxiWriteMasters    => coreAxilWriteMasters,
         mAxiWriteSlaves     => coreAxilWriteSlavEs,
         mAxiReadMasters     => coreAxilReadMasters,
         mAxiReadSlaves      => coreAxilReadSlaves);

   ----------------------------------------------------------------------------
   --                         ETH GT Mapping                                 --
   ----------------------------------------------------------------------------
   -- This VHDL wrapper is determined by the ZYNQ family type
   -- Zynq-7000:        rce-gen3-fw-lib/RceG3/hdl/zynq/RceEthGtMapping.vhd
   -- Zynq Ultrascale+: rce-gen3-fw-lib/RceG3/hdl/zynquplus/RceEthGtMapping.vhd
   ----------------------------------------------------------------------------
   U_RceEthernet : entity rce_gen3_fw_lib.RceEthernet
      generic map (
         -- Generic Configurations
         TPD_G              => TPD_C,
         RCE_DMA_MODE_G     => RCE_DMA_AXIS_C,
         ETH_TYPE_G         => "1000BASE-KX",
         MEMORY_TYPE_G      => "block",
         EN_JUMBO_G         => false,
         -- User ETH Configurations
         UDP_SERVER_EN_G    => true,
         UDP_SERVER_SIZE_G  => 2,
         UDP_SERVER_PORTS_G => SERVER_PORTS_C,
         BYP_EN_G           => false)
      port map (
         -- Clocks and resets
         clk312               => clk312,
         rst312               => rst312,
         clk200               => clk200,
         rst200               => rst200,
         clk156               => clk156,
         rst156               => rst156,
         clk125               => clk125,
         rst125               => rst125,
         clk62                => clk62,
         rst62                => rst62,
         stableClk            => stableClk,
         stableRst            => stableRst,
         -- PPI Interface
         dmaClk               => dmaClk(3),
         dmaRst               => dmaClkRst(3),
         dmaState             => dmaState(3),
         dmaIbMaster          => dmaIbMaster(3),
         dmaIbSlave           => dmaIbSlave(3),
         dmaObMaster          => dmaObMaster(3),
         dmaObSlave           => dmaObSlave(3),
         -- User ETH interface
         userEthClk           => userEthClk,
         userEthRst           => userEthClkRst,
         userEthIpAddr        => localIp,
         userEthMacAddr       => localMac,
         userEthUdpIbMaster   => userEthUdpIbMaster,
         userEthUdpIbSlave    => userEthUdpIbSlave,
         userEthUdpObMaster   => userEthUdpObMaster,
         userEthUdpObSlave    => userEthUdpObSlave,
         userEthBypIbMaster   => AXI_STREAM_MASTER_INIT_C,
         userEthBypIbSlave    => open,
         userEthBypObMaster   => open,
         userEthBypObSlave    => AXI_STREAM_SLAVE_FORCE_C,
         -- AXI-Lite Buses
         axilClk              => axilClk,
         axilRst              => axilRst,
         axilWriteMaster      => coreAxilWriteMasters(MAC_AXIL_INDEX_C),
         axilWriteSlave       => coreAxilWriteSlaves(MAC_AXIL_INDEX_C),
         axilReadMaster       => coreAxilReadMasters(MAC_AXIL_INDEX_C),
         axilReadSlave        => coreAxilReadSlaves(MAC_AXIL_INDEX_C),
         -- Ref Clock
         ethRefClk            => '0',
         -- Ethernet Lines
         ethRxP               => iethRxP,
         ethRxN               => iethRxN,
         ethTxP               => iethTxP,
         ethTxN               => iethTxN);

   armEthMode <= x"00000002";

   -- Show connections
   iethRxP(0) <= ethRxP;
   iethRxN(0) <= ethRxN;
   ethTxP     <= iethTxP(0);
   ethTxN     <= iethTxN(0);

   -------------------------------------------------------------------------------------------------
   -- UDP Engine
   -------------------------------------------------------------------------------------------------
   U_AxiLiteAsync : entity surf.AxiLiteAsync
      generic map (
         TPD_G => TPD_C)
      port map (
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => coreAxilReadMasters(UDP_AXIL_INDEX_C),
         sAxiReadSlave   => coreAxilReadSlaves(UDP_AXIL_INDEX_C),
         sAxiWriteMaster => coreAxilWriteMasters(UDP_AXIL_INDEX_C),
         sAxiWriteSlave  => coreAxilWriteSlaves(UDP_AXIL_INDEX_C),
         mAxiClk         => userEthClk,
         mAxiClkRst      => userEthClkRst,
         mAxiReadMaster  => udpAxilReadMaster,
         mAxiReadSlave   => udpAxilReadSlave,
         mAxiWriteMaster => udpAxilWriteMaster,
         mAxiWriteSlave  => udpAxilWriteSlave);

   U_UdpEngineWrapper : entity surf.UdpEngineWrapper
      generic map (
         TPD_G          => TPD_C,
         SERVER_EN_G    => true,
         SERVER_SIZE_G  => 2,
         SERVER_PORTS_G => SERVER_PORTS_C,
         CLIENT_EN_G    => false,
         DHCP_G         => false,
         CLK_FREQ_G     => 125.0e6)
      port map (
         localMac           => localMac,
         localIp            => localIp,
         obMacMaster        => userEthUdpObMaster,
         obMacSlave         => userEthUdpObSlave,
         ibMacMaster        => userEthUdpIbMaster,
         ibMacSlave         => userEthUdpIbSlave,
         obServerMasters    => udpObServerMasters,
         obServerSlaves     => udpObServerSlaves,
         ibServerMasters    => udpIbServerMasters,
         ibServerSlaves     => udpIbServerSlaves,
         axilWriteMaster    => udpAxilWriteMaster,
         axilWriteSlave     => udpAxilWriteSlave,
         axilReadMaster     => udpAxilReadMaster,
         axilReadSlave      => udpAxilReadSlave,
         clk                => userEthClk,
         rst                => userEthClkRst);

   U_Debug : entity surf.UdpDebugBridgeWrapper
      generic map (
         TPD_G => TPD_C)
      port map (
         -- Clock and Reset
         clk        => userEthClk,
         rst        => userEthClkRst,
         -- UDP XVC Interface
         obServerMaster => udpObServerMasters(1),
         obServerSlave  => udpObServerSlaves(1),
         ibServerMaster => udpIbServerMasters(1),
         ibServerSlave  => udpIbServerSlaves(1));

   -------------------------------------------------------------------------------------------------
   -- RSSI Engines
   -------------------------------------------------------------------------------------------------
   U_RssiCoreWrapper : entity surf.RssiCoreWrapper
      generic map (
         TPD_G                => TPD_C,
         CLK_FREQUENCY_G      => 125.0e6,
         WINDOW_ADDR_SIZE_G   => 4,
         SEGMENT_ADDR_SIZE_G  => 7,
         BYPASS_CHUNKER_G     => false,
         PIPE_STAGES_G        => 1,
         APP_STREAMS_G        => 1,
         TIMEOUT_UNIT_G       => 1.0e-3,
         SERVER_G             => true,
         RETRANSMIT_ENABLE_G  => true,
         MAX_NUM_OUTS_SEG_G   => 16,
         INIT_SEQ_N_G         => 16#80#,
         APP_ILEAVE_EN_G      => true,
         BYP_TX_BUFFER_G      => false,
         BYP_RX_BUFFER_G      => false,
         ILEAVE_ON_NOTVALID_G => true,
         APP_AXIS_CONFIG_G    => (0 => APP_AXIS_CONFIG_C),
         TSP_AXIS_CONFIG_G    => EMAC_AXIS_CONFIG_C,
         MAX_SEG_SIZE_G       => 1024)
      port map (
         clk_i                => userEthClk,
         rst_i                => userEthClkRst,
         sAppAxisMasters_i(0) => rssiIbMaster,
         sAppAxisSlaves_o(0)  => rssiIbSlave,
         mAppAxisMasters_o(0) => rssiObMaster,
         mAppAxisSlaves_i(0)  => rssiObSlave,
         sTspAxisMaster_i     => udpObServerMasters(0),
         sTspAxisSlave_o      => udpObServerSlaves(0),
         mTspAxisMaster_o     => udpIbServerMasters(0),
         mTspAxisSlave_i      => udpIbServerSlaves(0),
         openRq_i             => '1',
         axiClk_i             => axilClk,
         axiRst_i             => axilRst,
         axilReadMaster       => coreAxilReadMasters(RSSI_AXIL_INDEX_C),
         axilReadSlave        => coreAxilReadSlaves(RSSI_AXIL_INDEX_C),
         axilWriteMaster      => coreAxilWriteMasters(RSSI_AXIL_INDEX_C),
         axilWriteSlave       => coreAxilWriteSlaves(RSSI_AXIL_INDEX_C),
         statusReg_o          => open);

   ----------------------------------------------------
   -- Fan In Board Core
   ----------------------------------------------------
   U_FanInBoard: entity ucsc_hn.FanInBoard
      generic map (
         TPD_G         => TPD_C,
         MASTER_G      => false,
         AXIS_CONFIG_G => APP_AXIS_CONFIG_C
      ) port map (
         axilClk              => axilClk,
         axilRst              => axilRst,
         axilReadMaster       => extAxilReadMaster,
         axilReadSlave        => extAxilReadSlave,
         axilWriteMaster      => extAxilWriteMaster,
         axilWriteSlave       => extAxilWriteSlave,
         dataClk              => userEthClk,
         dataClkRst           => userEthClkRst,
         dataObMaster         => rssiIbMaster,
         dataObSlave          => rssiIbSlave,
         dataIbMaster         => rssiObMaster,
         dataIbSlave          => rssiObSlave,
         clockHubInP          => clockHubP,
         clockHubInN          => clockHubN,
         syncHubP             => syncHubP,
         syncHubN             => syncHubN,
         clockOutP            => clockOutP,
         clockOutN            => clockOutN,
         syncOutP             => syncOutP,
         syncOutN             => syncOutN,
         fpgaProgL            => fpgaProgL,
         rxDataP              => rxDataP,
         rxDataN              => rxDataN,
         txData               => txData
      );

   -- DMA Interfaces are not used
   dmaClk(2 downto 0) <= (others=>axiDmaClk);
   dmaClkRst(2 downto 0) <= (others=>axiDmaRst);

   --dmaObMaster(2 downto 0)
   dmaObSlave(2 downto 0)   <= dmaIbSlave(2 downto 0);
   dmaIbMaster(2 downto 0)  <= dmaObMaster(2 downto 0);
   --dmaIbSlave(2 downto 0)

end architecture STRUCTURE;

