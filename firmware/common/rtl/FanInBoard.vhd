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
      TPD_G  : time := 1 ns
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
      dataIbMaster        : in    AxiStreamMasterType;
      dataIbSlave         : out   AxiStreamSlaveType;
      dataObMaster        : out   AxiStreamMasterType;
      dataObSlave         : in    AxiStreamSlaveType;

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


begin

   clockOut <= clockIn;
   syncOut  <= syncIn;
   txData   <= (others=>'0');

   dataIbSlave <= AXI_STREAM_SLAVE_FORCE_C;

   U_PrbsTx: entity surf.SsiPrbsTx 
      generic map (
         TPD_G                      => TPD_G,
         PRBS_SEED_SIZE_G           => 32,
         GEN_SYNC_FIFO_G            => false,
         MASTER_AXI_PIPE_STAGES_G   => 1,
         MASTER_AXI_STREAM_CONFIG_G => RCEG3_AXIS_DMA_CONFIG_C)
      port map (
         mAxisClk        => dataClk,
         mAxisRst        => dataClkRst,
         mAxisMaster     => dataObMaster,
         mAxisSlave      => dataObSlave,
         locClk          => axilClk,
         locRst          => axilRst,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

end architecture STRUCTURE;

