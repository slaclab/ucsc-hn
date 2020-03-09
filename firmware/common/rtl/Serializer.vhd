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
      MEMORY_TYPE_G     : string               := "distributed";
      FIFO_ADDR_WIDTH_G : positive             := 8;
      DATA_WIDTH_G      : integer range 5 to 8 := 8);
   port(
      clk         : in  sl;
      rst         : in  sl;
      tx          : out sl;
      --AXI
      mAxisClk    : in  sl;
      mAxisRst    : in  sl;
      mAxisMaster : in  AxiStreamMasterType;
      mAxisSlave  : out AxiStreamSlaveType);
end entity Serializer;

architecture Behavioral of Serializer is

   signal dinFrameDetect       : slv(7 downto 0);
   signal dinFrameDetectValid  : sl;
   signal doutFrameDetect      : slv(7 downto 0);
   signal doutFrameDetectValid : sl;

   signal fifoDin       : slv(7 downto 0);
   signal fifoDinValid  : sl;
   signal fifoWrEn      : sl;
   signal fifoDout      : slv(7 downto 0);
   signal fifoDoutValid : sl;

   signal uartWrData  : slv(7 downto 0);
   signal uartWrValid : sl;
   signal uartWrReady : sl;
   signal uartTx      : sl;

begin

------------------------------------------------------------------------------------------------
-- Detect start (0xC0) and stop (0xFF) frame. Also remove src and dst id from data.
------------------------------------------------------------------------------------------------
   dinFrameDetect      <= mAxisMaster.tData(7 downto 0);
   dinFrameDetectValid <= mAxisMaster.tValid;
   U_FrameDetect : entity work.FrameDetect
      generic map (
         TPD_G            => TPD_G,
         REMOVE_SRC_DST_G => '1')
      port map (
         -- Clock and Reset
         clk       => clk,
         rst       => rst,
         -- Data Interface
         din       => dinFrameDetect,
         dinValid  => dinFrameDetectValid,
         dout      => doutFrameDetect,
         doutValid => doutFrameDetectValid);

------------------------------------------------------------------------------------------------
-- UART Tx
------------------------------------------------------------------------------------------------
   --Fifo Tx
   fifoDin      <= doutFrameDetect;
   fifoDinValid <= doutFrameDetectValid;
   U_Fifo_Tx : entity surf.Fifo
      generic map (
         TPD_G           => TPD_G,
         GEN_SYNC_FIFO_G => true,
         MEMORY_TYPE_G   => MEMORY_TYPE_G,
         FWFT_EN_G       => true,
         PIPE_STAGES_G   => 0,
         DATA_WIDTH_G    => DATA_WIDTH_G,
         ADDR_WIDTH_G    => FIFO_ADDR_WIDTH_G)
      port map (
         rst      => rst,
         wr_clk   => clk,
         wr_en    => fifoDinValid,
         din      => fifoDin,
         not_full => fifoWrEn,
         rd_clk   => clk,
         rd_en    => uartWrReady,
         dout     => fifoDout,
         valid    => fifoDoutValid); 

   -- UART TX
   uartWrData  <= fifoDout;
   uartWrValid <= fifoDoutValid;
   U_UartTx : entity surf.UartTx
      generic map (
         TPD_G        => TPD_G,
         STOP_BITS_G  => 1,
         PARITY_G     => "NONE",
         BAUD_MULT_G  => 4,
         DATA_WIDTH_G => DATA_WIDTH_G)
      port map (
         clk     => clk,
         rst     => rst,
         clkEn   => '1',
         wrData  => uartWrData,
         wrValid => uartWrValid,
         wrReady => uartWrReady,
         tx      => uartTx);

   -- Output
   mAxisSlave.tReady <= fifoWrEn;
   tx                <= uartTx;
end Behavioral;

