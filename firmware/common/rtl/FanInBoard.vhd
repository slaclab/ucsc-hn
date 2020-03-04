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

entity FanInBoard is
   generic (
      TPD_G         : time := 1 ns;
      AXIS_CONFIG_G : AxiStreamConfigType := AXI_STREAM_CONFIG_INIT_C
   );
   port (

      -- AXI-Lite clock and reset
      axilClk             : in    sl;
      axilRst             : in    sl;

      -- External Axi Bus, 0xA0000000 - 0xAFFFFFFF  (axilClk domain)
      axilReadMaster      : in    AxiLiteReadMasterType;
      axilReadSlave       : out   AxiLiteReadSlaveType;
      axilWriteMaster     : in    AxiLiteWriteMasterType;
      axilWriteSlave      : out   AxiLiteWriteSlaveType;

      -- Data Interfaces
      dataClk             : in    sl;
      dataClkRst          : in    sl;
      dataIbMasters       : in    AxiStreamMasterArray(30 downto 0);
      dataIbSlaves        : out   AxiStreamSlaveArray(30 downto 0);
      dataObMasters       : out   AxiStreamMasterArray(30 downto 0);
      dataObSlaves        : in    AxiStreamSlaveArray(30 downto 0);

      -- Rena fan in board clocks
      clockIn     : in    sl;
      clockOut    : out   sl;

      -- Sync signals
      syncIn      : in    sl;
      syncOut     : out   sl;

      -- Data inputs
      rxData      : in    slv(30 downto 1);

      -- Control outputs
      txData      : out   slv(6  downto 1)
   );
end FanInBoard;

architecture STRUCTURE of FanInBoard is

   signal intObMasters  : AxiStreamMasterArray(30 downto 0);
   signal intObSlaves   : AxiStreamSlaveArray(30 downto 0);

begin

   clockOut <= clockIn;
   syncOut  <= syncIn;
   txData   <= (others=>'0');

   U_PrbsTx: entity surf.SsiPrbsTx
      generic map (
         TPD_G                      => TPD_G,
         PRBS_SEED_SIZE_G           => 32,
         GEN_SYNC_FIFO_G            => false,
         MASTER_AXI_PIPE_STAGES_G   => 1,
         MASTER_AXI_STREAM_CONFIG_G => AXIS_CONFIG_G)
      port map (
         mAxisClk        => dataClk,
         mAxisRst        => dataClkRst,
         mAxisMaster     => dataObMasters(0),
         mAxisSlave      => dataObSlaves(0),
         locClk          => axilClk,
         locRst          => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   U_DeserializerGen : for i in 1 to 30 generate

      U_Deserializer : entity work.Deserializer
         generic map (
            TPD_G         => TPD_G,
            AXIS_CONFIG_G => AXIS_CONFIG_G)
         port map (
            clk         => clockIn,
            rst         => dataClkRst,
            boardid     => "001",
            rx          => rxData(i),
            mAxisClk    => dataClk,
            mAxisRst    => dataClkRst,
            mAxisMaster => dataObMasters(i),
            mAxisSlave  => dataObSlaves(i));
   end generate;

   -- Unused Intputs
   dataIbSlaves(30 downto 0) <= (others=>AXI_STREAM_SLAVE_FORCE_C);

end architecture STRUCTURE;

