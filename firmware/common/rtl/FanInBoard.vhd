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
      clockHubInP  : in    sl := '0';
      clockHubInN  : in    sl := '0';
      clockHubOutP : out   sl;
      clockHubOutN : out   sl;
      syncHubP     : inout sl;
      syncHubN     : inout sl;

      -- Rena Clock and sync
      clockOutP  : out sl;
      clockOutN  : out sl;
      syncOutP   : out sl;
      syncOutN   : out sl;
      fpgaProgL  : out sl;

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

   signal syncGen    : sl;
   signal syncInt    : sl;
   signal syncTmp    : sl;
   signal syncReg    : sl;
   signal syncOut    : sl;
   signal syncHubT   : sl;
   signal syncHubIn  : sl;
   signal syncHubOut : sl;

   signal clockHubIn  : sl;
   signal clockHubOut : sl;
   signal clockOut    : sl;

   signal rxData : slv(30 downto 1);

   signal renaClkCount : slv(15 downto 0);
   signal sysClkCount  : slv(15 downto 0);

   signal mmcmReset  : sl;
   signal mmcmLocked : sl;

begin

   -------------------------------
   -- AXI Bus
   -------------------------------
   U_Regs : entity ucsc_hn.FanInRegs
      generic map (TPD_G => TPD_G)
      port map (
         axiClk         => axilClk,
         axiRst         => axilRst,
         axiReadMaster  => axilReadMaster,
         axiReadSlave   => axilReadSlave,
         axiWriteMaster => axilWriteMaster,
         axiWriteSlave  => axilWriteSlave,
         syncGen        => syncGen,
         fpgaProgL      => fpgaProgL,
         rxEnable       => rxEnable,
         currRxData     => currRxData,
         countRst       => countRst,
         rxPackets      => rxPackets,
         dropBytes      => dropBytes,
         sysClkCount    => sysClkCount,
         renaClkCount   => renaClkCount,
         mmcmReset      => mmcmReset,
         mmcmLocked     => mmcmLocked);

   -------------------------------
   -- Hub/Local Clock Control
   -------------------------------

   U_MasterClockGen: if MASTER_G = true generate

      U_RenaClkGen : entity surf.ClockManager7
         generic map(
            TPD_G              => TPD_G,
            TYPE_G             => "MMCM",
            INPUT_BUFG_G       => false,
            NUM_CLOCKS_G       => 2,
            -- MMCM attributes
            CLKIN_PERIOD_G     => 8.0,  -- 125Mhz
            CLKFBOUT_MULT_F_G  => 8.0,  -- 1Ghz
            CLKOUT0_DIVIDE_F_G => 20.0, -- 50Mhz
            CLKOUT1_DIVIDE_G   => 5)    -- 200Mhz
         port map(
            clkIn     => dataClk,
            rstIn     => dataClkRst,
            locked    => mmcmLocked,
            clkOut(0) => renaClk,
            clkOut(1) => sysClk,
            rstOut(0) => renaClkRst,
            rstOut(1) => sysClkRst);

      -- Drive output clock using DDR buffer
      ODDR_HUB : ODDR
         port map (
            C  => renaClk,
            Q  => clockHubOut,
            CE => '1',
            D1 => '1',
            D2 => '0',
            R  => renaClkRst,
            S  => '0');

      U_ClockHubBuf : OBUFDS
         port map(
            I     => clockHubOut,
            O     => clockHubOutP,
            OB    => clockHubOutN
         );

      clockHubIn <= '0';

   end generate;

   U_SlaveClockGen: if MASTER_G = false generate

      U_ClockHubBuf : IBUFGDS
         generic map ( DIFF_TERM => true )
         port map(
            O     => clockHubIn,
            I     => clockHubInP,
            IB    => clockHubInN
         );

      U_RenaClkGen : entity surf.ClockManager7
         generic map(
            TPD_G              => TPD_G,
            TYPE_G             => "MMCM",
            NUM_CLOCKS_G       => 2,
            -- MMCM attributes
            CLKIN_PERIOD_G     => 20.0, -- 50Mhz
            CLKFBOUT_MULT_F_G  => 20.0, -- 1Ghz
            CLKOUT0_DIVIDE_F_G => 20.0, -- 50Mhz
            CLKOUT1_DIVIDE_G   => 5)    -- 200Mhz
         port map (
            clkIn     => clockHubIn,
            rstIn     => mmcmReset,
            locked    => mmcmLocked,
            clkOut(0) => renaClk,
            clkOut(1) => sysClk,
            rstOut(0) => renaClkRst,
            rstOut(1) => sysClkRst);

      clockHubOut <= '0';

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
               syncHubOut <= '0';
               syncReg    <= '0';
            else
               syncHubOut <= syncInt;
               syncReg    <= syncHubOut;
            end if;
        end if;
      end process;

      syncHubT <= '0';

   end generate;

   U_SyncHubIoBuf : IOBUFDS
   generic map ( DIFF_TERM => (not MASTER_G) )
      port map(
         I      => syncHubOut,
         O      => syncHubIn,
         T      => syncHubT,
         IO     => syncHubP,
         IOB    => syncHubN
      );

   U_SlaveSyncGen: if MASTER_G = false generate
      syncHubOut <= '0';
      syncInt    <= '0';
      syncHubT   <= '1';

      process (renaClk) begin
         if falling_edge(renaCLk) then
            if renaClkRst = '1' then
               syncReg <= '0';
            else
               syncReg <= syncHubIn;
            end if;
        end if;
      end process;
   end generate;

   -------------------------------
   -- Rena Sync Output
   -------------------------------
   process (renaClk) begin
      if rising_edge(renaCLk) then
         if renaClkRst = '1' then
            syncTmp    <= '0';
         else
            syncTmp    <= syncReg;
         end if;
     end if;
   end process;

   process (renaClk) begin
      if falling_edge(renaCLk) then
         if renaClkRst = '1' then
            syncOut    <= '0';
         else
            syncOut    <= syncTmp;
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
           ILEAVE_EN_G          => false,
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
        ILEAVE_EN_G          => false,
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

   process (renaClk) begin
      if falling_edge(renaCLk) then
         if renaClkRst = '1' then
            renaClkCount <= (others=>'0') after TPD_G;
         else
            renaClkCount <= renaClkCount + 1 after TPD_G;
         end if;
     end if;
   end process;

   process (sysClk) begin
      if falling_edge(sysCLk) then
         if sysClkRst = '1' then
            sysClkCount <= (others=>'0') after TPD_G;
         else
            sysClkCount <= sysClkCount + 1 after TPD_G;
         end if;
     end if;
   end process;

end architecture STRUCTURE;

