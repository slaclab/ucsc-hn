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
-- MultiRena.vhd
-------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.numeric_std.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library rce_gen3_fw_lib;
use rce_gen3_fw_lib.RceG3Pkg.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;
use surf.AxiStreamPkg.all;

library ucsc_hn;

entity FanInBoard is
   generic (
      TPD_G         : time                := 1 ns;
      MASTER_G      : boolean             := true;
      AXIS_CONFIG_G : AxiStreamConfigType := AXI_STREAM_CONFIG_INIT_C
      );
   port (

      -- AXI-Lite clock and reset
      axilClk : in sl;
      axilRst : in sl;

      -- External Axi Bus, 0xA0000000 - 0xAFFFFFFF  (axilClk domain)
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;

      -- Data Interfaces
      dataClk      : in  sl;
      dataClkRst   : in  sl;
      dataIbMaster : in  AxiStreamMasterType;
      dataIbSlave  : out AxiStreamSlaveType;
      dataObMaster : out AxiStreamMasterType;
      dataObSlave  : in  AxiStreamSlaveType;

      -- Hub board clock and sync signals
      clockHubP : inout sl;
      clockHubN : inout sl;
      syncHubP  : inout sl;
      syncHubN  : inout sl;

      -- Rena Clock and sync
      clockOutP : out sl;
      clockOutN : out sl;
      syncOutP  : out sl;
      syncOutN  : out sl;
      fpgaProgL : out sl;

      -- Data inputs
      rxDataP : in slv(30 downto 1);
      rxDataN : in slv(30 downto 1);

      -- Control outputs
      txData : out slv(6 downto 1)
      );
end FanInBoard;

architecture STRUCTURE of FanInBoard is

   constant TDEST_ROUTES0_C : Slv8Array(5 downto 0) := (others=> "--------");
   constant TDEST_ROUTES1_C : Slv8Array(4 downto 0) := (others=> "--------");

   signal intObMasters : AxiStreamMasterArray(30 downto 1);
   signal intObSlaves  : AxiStreamSlaveArray(30 downto 1);

   signal muxObMasters : AxiStreamMasterArray(4 downto 0);
   signal muxObSlaves  : AxiStreamSlaveArray(4 downto 0);

   signal batchObMaster : AxiStreamMasterType;
   signal batchObSlave  : AxiStreamSlaveType;

   signal sysClk     : sl;
   signal sysClkRst  : sl;
   signal renaClk    : sl;
   signal renaClkRst : sl;

   signal intReadMaster  : AxiLiteReadMasterType;
   signal intReadSlave   : AxiLiteReadSlaveType;
   signal intWriteMaster : AxiLiteWriteMasterType;
   signal intWriteSlave  : AxiLiteWriteSlaveType;

   signal countRst  : sl;
   signal rxPackets : Slv32Array(30 downto 1);
   signal dropBytes : Slv32Array(30 downto 1);

   signal currRxData : slv(30 downto 1);
   signal rxEnable   : slv(30 downto 1);

   signal tx : sl;

   signal syncGen : sl;
   signal syncInt : sl;
   signal syncReg : sl;
   signal syncOut : sl;
   signal syncHub : sl;

   signal clockHub : sl;
   signal clockOut : sl;

   signal rxData : slv(30 downto 1);

begin

   -------------------------------
   -- AXI Bus
   -------------------------------
   U_AxiLiteAsync : entity surf.AxiLiteAsync
      generic map (TPD_G => TPD_G) port map (
         sAxiClk         => axilClk,
         sAxiClkRst      => axilRst,
         sAxiReadMaster  => axilReadMaster,
         sAxiReadSlave   => axilReadSlave,
         sAxiWriteMaster => axilWriteMaster,
         sAxiWriteSlave  => axilWriteSlave,
         mAxiClk         => sysClk,
         mAxiClkRst      => sysClkRst,
         mAxiReadMaster  => intReadMaster,
         mAxiReadSlave   => intReadSlave,
         mAxiWriteMaster => intWriteMaster,
         mAxiWriteSlave  => intWriteSlave);

   U_Regs : entity ucsc_hn.FanInRegs
      generic map (TPD_G => TPD_G)
      port map (
         axiClk         => sysClk,
         axiRst         => sysClkRst,
         axiReadMaster  => intReadMaster,
         axiReadSlave   => intReadSlave,
         axiWriteMaster => intWriteMaster,
         axiWriteSlave  => intWriteSlave,
         syncGen        => syncGen,
         fpgaProgL      => fpgaProgL,
         rxEnable       => rxEnable,
         currRxData     => currRxData,
         countRst       => countRst,
         rxPackets      => rxPackets,
         dropBytes      => dropBytes);

   -------------------------------
   -- Hub/Local Clock Control
   -------------------------------
   U_MasterClockGen: if MASTER_G = true generate

      U_RenaClkGen : entity surf.ClockManager7
         generic map(
            TPD_G              => TPD_G,
            TYPE_G             => "MMCM",
            INPUT_BUFG_G       => false,
            FB_BUFG_G          => false,   -- minimize BUFG for 7-series FPGAs
            RST_IN_POLARITY_G  => '1',
            NUM_CLOCKS_G       => 1,
            -- MMCM attributes
            CLKIN_PERIOD_G     => 8.0,  -- 125Mhz
            CLKFBOUT_MULT_F_G  => 8.0,  -- 1Ghz
            CLKOUT0_DIVIDE_F_G => 20.0) -- 50Mhz
         port map(
            clkIn     => dataClk,
            rstIn     => dataClkRst,
            clkOut(0) => renaClk,
            rstOut(0) => renaClkRst);

      -- Drive output clock using DDR buffer
      ODDR_HUB : ODDR
         port map (
            C  => renaClk,
            Q  => clockHub,
            CE => '1',
            D1 => '1',
            D2 => '0',
            R  => renaClkRst,
            S  => '0');

      U_ClockOutBuf : OBUFDS
         port map(
            O      => clockHubP,
            OB     => clockHubN,
            I      => clockHub
         );

   end generate;

   U_SlaveClockGen: if MASTER_G = false generate

      U_ClockHubBuf : IBUFGDS
         generic map ( DIFF_TERM => true )
         port map(
            I      => clockHubP,
            IB     => clockHubN,
            O      => renaClk
         );

      RstSync_1 : entity surf.RstSync
         generic map (
            TPD_G           => TPD_G,
            IN_POLARITY_G   => '1',
            OUT_POLARITY_G  => '1',
            BYPASS_SYNC_G   => false,
            RELEASE_DELAY_G => 10)
         port map (
            clk      => renaClk,
            asyncRst => dataClkRst,
            syncRst  => renaClkRst);

   end generate;

   -------------------------------
   -- Hub/Local Sync Select
   -------------------------------
   U_MasterSyncGen: if MASTER_G = true generate

      U_RstSync: entity surf.SynchronizerOneShot
         generic map (
            TPD_G => TPD_G
         ) port map (
            clk     => renaClk,
            rst     => renaClkRst,
            dataIn  => syncGen,
            dataOut => syncInt);

      process (renaClk) begin
         if rising_edge(renaCLk) then
            if renaClkRst = '1' then
               syncHub <= '0';
            else
               syncHub <= syncInt;
            end if;
        end if;
      end process;

      U_SyncHubOutBuf : OBUFDS
         port map(
            I      => syncHub,
            O      => syncHubP,
            OB     => syncHubN
         );

   end generate;

   U_SlaveSyncGen: if MASTER_G = false generate
      syncInt <= '0';
      syncHub <= '0';
   end generate;

   U_SyncHubInBuf : IBUFDS
      generic map ( DIFF_TERM => (not MASTER_G) )
      port map(
         I      => syncHubP,
         IB     => syncHubN,
         O      => syncHub
      );

   process (renaClk) begin
      if falling_edge(renaCLk) then
         if renaClkRst = '1' then
            syncReg <= '0';
         else
            syncReg <= syncHub;
         end if;
     end if;
   end process;

   -------------------------------
   -- Rena Sync Output
   -------------------------------
   process (renaClk) begin
      if rising_edge(renaCLk) then
         if renaClkRst = '1' then
            syncOut <= '0';
         else
            syncOut <= syncReg;
         end if;
     end if;
   end process;

   U_SyncOutBuf : OBUFDS
      port map(
         O      => syncOutP,
         OB     => syncOutN,
         I      => syncOut
      );

   -------------------------------
   -- 2X Clock Generation
   -------------------------------
   U_SysClkGen : entity surf.ClockManager7
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => false,   -- minimize BUFG for 7-series FPGAs
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 1,
         -- MMCM attributes
         CLKIN_PERIOD_G     => 20.0,  -- 50Mhz
         CLKFBOUT_MULT_F_G  => 20.0,  -- 1Ghz
         CLKOUT0_DIVIDE_F_G => 5.0)   -- 200Mhz
      port map (
         clkIn     => renaClk,
         rstIn     => renaClkRst,
         clkOut(0) => sysClk,
         rstOut(0) => sysClkRst);

   -------------------------------
   -- Rena Clock Output
   -------------------------------

   -- Drive output clock using DDR buffer
   ODDR_I : ODDR
      port map (
         C  => renaClk,
         Q  => clockOut,
         CE => '1',
         D1 => '1',
         D2 => '0',
         R  => renaClkRst,
         S  => '0');

   U_ClockOutBuf : OBUFDS
      port map(
         O      => clockOutP,
         OB     => clockOutN,
         I      => clockOut
      );

   -------------------------------
   -- Inbound Path
   -------------------------------
   U_RxDataGen : for i in 1 to 30 generate

      U_RxDataBuf : IBUFDS
         generic map ( DIFF_TERM => true )
         port map(
            I      => rxDataP(i),
            IB     => rxDataN(i),
            O      => rxData(i)
         );
   end generate;

   U_DeserializerGen : for i in 1 to 30 generate
      U_Deserializer : entity ucsc_hn.Deserializer
         generic map (
            TPD_G         => TPD_G,
            TDEST_G       => (i-1), -- TDEST = [29:0]
            AXIS_CONFIG_G => AXIS_CONFIG_G)
         port map (
            sysClk      => sysClk,
            sysClkRst   => sysClkRst,
            rx          => rxData(i),
            rxEnable    => rxEnable(i),
            currRxData  => currRxData(i),
            countRst    => countRst,
            rxPackets   => rxPackets(i),
            dropBytes   => dropBytes(i),
            mAxisClk    => dataClk,
            mAxisRst    => dataClkRst,
            mAxisMaster => intObMasters(i),
            mAxisSlave  => intObSlaves(i));
   end generate;

   -- First stage muxes
  U_PreMux : for i in 0 to 4 generate
     U_Mux : entity surf.AxiStreamMux
        generic map (
           TPD_G                => TPD_G,
           MODE_G               => "ROUTED",
           TDEST_ROUTES_G       => TDEST_ROUTES0_C,
           ILEAVE_EN_G          => true,
           ILEAVE_ON_NOTVALID_G => true,
           ILEAVE_REARB_G       => 128,
           PIPE_STAGES_G        => 1,
           NUM_SLAVES_G         => 6
        ) port map (
           axisClk      => dataClk,
           axisRst      => dataClkRst,
           sAxisMasters => intObMasters(i*6+6 downto i*6+1),
           sAxisSlaves  => intObSlaves(i*6+6 downto i*6+1),
           mAxisMaster  => muxObMasters(i),
           mAxisSlave   => muxObSlaves(i));
  end generate;

  -- Outbound mux
  U_ObMux : entity surf.AxiStreamMux
     generic map (
        TPD_G                => TPD_G,
        MODE_G               => "ROUTED",
        TDEST_ROUTES_G       => TDEST_ROUTES1_C,
        ILEAVE_EN_G          => true,
        ILEAVE_ON_NOTVALID_G => true,
        ILEAVE_REARB_G       => 128,
        PIPE_STAGES_G        => 1,
        NUM_SLAVES_G         => 5
     ) port map (
        axisClk      => dataClk,
        axisRst      => dataClkRst,
        sAxisMasters => muxObMasters,
        sAxisSlaves  => muxObSlaves,
        mAxisMaster  => batchObMaster,
        mAxisSlave   => batchObSlave);

   U_ObBatch: entity surf.AxiStreamBatcher
      generic map (
         TPD_G                        => TPD_G,
         MAX_NUMBER_SUB_FRAMES_G      => 128,
         SUPER_FRAME_BYTE_THRESHOLD_G => 1400,
         MAX_CLK_GAP_G                => 256,
         AXIS_CONFIG_G                => AXIS_CONFIG_G,
         INPUT_PIPE_STAGES_G          => 0,
         OUTPUT_PIPE_STAGES_G         => 1)
      port map (
         axisClk     => dataClk,
         axisRst     => dataClkRst,
         sAxisMaster => batchObMaster,
         sAxisSlave  => batchObSlave,
         mAxisMaster => dataObMaster,
         mAxisSlave  => dataObSlave);

   -------------------------------
   -- Outbound Path
   -------------------------------
   U_Serializer : entity work.Serializer
      generic map (
         TPD_G         => TPD_G,
         AXIS_CONFIG_G => AXIS_CONFIG_G)
      port map (
         sysClk      => sysClk,
         sysRst      => sysClkRst,
         renaClk     => renaClk,
         renaRst     => renaClkRst,
         tx          => tx,
         mAxisClk    => dataClk,
         mAxisRst    => dataClkRst,
         mAxisMaster => dataIbMaster,
         mAxisSlave  => dataIbSlave);

   txData <= (others => tx);

end architecture STRUCTURE;

