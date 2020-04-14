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

      -- Rena fan in board clocks
      clockIn  : in  sl;
      clockOut : out sl;

      -- Sync signals
      syncIn  : in  sl;
      syncOut : out sl;

      -- Data inputs
      rxData : in slv(30 downto 1);

      -- Control outputs
      txData : out slv(6 downto 1)
      );
end FanInBoard;

architecture STRUCTURE of FanInBoard is

   constant TDEST_ROUTES_C : Slv8Array(30 downto 1) := (others=> "00000000");

   signal intObMasters : AxiStreamMasterArray(30 downto 1);
   signal intObSlaves  : AxiStreamSlaveArray(30 downto 1);

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
   signal overSize  : Slv32Array(30 downto 1);

   signal tx : sl;

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
         currRxData     => rxData,
         countRst       => countRst,
         rxPackets      => rxPackets,
         dropBytes      => dropBytes,
         overSize       => overSize);

   -------------------------------
   -- Clocking
   -------------------------------
   U_MMCM : entity surf.ClockManager7
      generic map(
         TPD_G              => TPD_G,
         TYPE_G             => "MMCM",
         INPUT_BUFG_G       => false,
         FB_BUFG_G          => false,   -- minimize BUFG for 7-series FPGAs
         RST_IN_POLARITY_G  => '1',
         NUM_CLOCKS_G       => 2,
         -- MMCM attributes
         CLKIN_PERIOD_G     => 8.0, -- 125Mhz
         CLKFBOUT_MULT_F_G  => 8.0, -- 1Ghz
         CLKOUT0_DIVIDE_F_G => 5.0, -- 200Mhz
         CLKOUT1_DIVIDE_G   => 20)  -- 50Mhz
      port map(
         clkIn     => dataClk,
         rstIn     => dataClkRst,
         clkOut(0) => sysClk,
         clkOut(1) => renaClk,
         rstOut(0) => sysClkRst,
         rstOut(1) => renaClkRst);

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

   syncOut <= syncIn;

   -------------------------------
   -- Inbound Path
   -------------------------------

   U_DeserializerGen : for i in 1 to 30 generate
      U_Deserializer : entity ucsc_hn.Deserializer
         generic map (
            TPD_G         => TPD_G,
            AXIS_CONFIG_G => AXIS_CONFIG_G)
         port map (
            sysClk      => sysClk,
            sysClkRst   => sysClkRst,
            rx          => rxData(i),
            countRst    => countRst,
            rxPackets   => rxPackets(i),
            dropBytes   => dropBytes(i),
            overSize    => overSize(i),
            mAxisClk    => dataClk,
            mAxisRst    => dataClkRst,
            mAxisMaster => intObMasters(i),
            mAxisSlave  => intObSlaves(i));
   end generate;

   --Outbound mux
   --U_ObMux : entity surf.AxiStreamMux
      --generic map (
         --TPD_G          => TPD_G,
         --TDEST_ROUTES_G => TDEST_ROUTES_C,
         --NUM_SLAVES_G   => 30
      --) port map (
         --axisClk      => dataClk,
         --axisRst      => dataClkRst,
         --sAxisMasters => intObMasters,
         --sAxisSlaves  => intObSlaves,
         --mAxisMaster  => dataObMaster,
         --mAxisSlave   => dataObSlave);

   dataObMaster   <= intObMasters(25);
   intObSlaves(25) <= dataObSlave;
   intObSlaves(30 downto 26) <= (others=>AXI_STREAM_SLAVE_INIT_C);
   intObSlaves(24 downto  1) <= (others=>AXI_STREAM_SLAVE_INIT_C);

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

