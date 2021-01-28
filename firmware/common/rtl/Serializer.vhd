------------------------------------------------------------------------------
-- This file is part of 'RCE Development Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'RCE Development Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiStreamPkg.all;

entity Serializer is
   generic(
      TPD_G             : time                 := 1 ns;
      AXIS_CONFIG_G     : AxiStreamConfigType  := AXI_STREAM_CONFIG_INIT_C);
   port(
      sysClk      : in  sl;
      sysRst      : in  sl;
      renaClk     : in  sl;
      renaRst     : in  sl;
      tx          : out sl;
      --AXI
      mAxisClk    : in  sl;
      mAxisRst    : in  sl;
      mAxisMaster : in  AxiStreamMasterType;
      mAxisSlave  : out AxiStreamSlaveType);
end entity Serializer;

architecture Behavioral of Serializer is

   constant INT_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => false,
      TDATA_BYTES_C => 1,
      TDEST_BITS_C  => 0,
      TID_BITS_C    => 0,
      TKEEP_MODE_C  => TKEEP_COMP_C,
      TUSER_BITS_C  => 2,
      TUSER_MODE_C  => TUSER_FIRST_LAST_C);

   signal intAxisMaster : AxiStreamMasterType;
   signal intAxisSlave  : AxiStreamSlaveType;
   signal intTx : sl;
   signal regTx : sl;

begin

   U_AxiFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         PIPE_STAGES_G       => 4,
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => INT_AXIS_CONFIG_C
      ) port map (
         sAxisClk    => mAxisClk,
         sAxisRst    => mAxisRst,
         sAxisMaster => mAxisMaster,
         sAxisSlave  => mAxisSlave,
         mAxisClk    => sysClk,
         mAxisRst    => sysRst,
         mAxisMaster => intAxisMaster,
         mAxisSlave  => intAxisSlave);

   U_UartTx : entity surf.UartTx
      generic map (
         TPD_G        => TPD_G,
         STOP_BITS_G  => 1,
         PARITY_G     => "NONE",
         BAUD_MULT_G  => 4,
         DATA_WIDTH_G => 8)
      port map (
         clk       => sysClk,
         rst       => sysRst,
         baudClkEn => '1',
         wrData    => intAxisMaster.tData(7 downto 0),
         wrValid   => intAxisMaster.tValid,
         wrReady   => intAxisSlave.tReady,
         tx        => intTx);

   process (renaClk) is
   begin
      if (rising_edge(renaClk)) then
         if renaRst = '1' then
            regTx <= '0' after TPD_G;
            tx    <= '0' after TPD_G;
         else
            regTx <= intTx after TPD_G;
            tx    <= regTx after TPD_G;
         end if;
      end if;
   end process;

end Behavioral;

