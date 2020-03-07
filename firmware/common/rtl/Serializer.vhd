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
		TPD_G			  : time	  := 1 ns;
		CLK_FREQ_G        : real      := 50.0E+6;
		BAUD_RATE_G       : positive  := 115200;
		MEMORY_TYPE_G    : string    := "block";
		FIFO_ADDR_WIDTH_G : positive  := 8);
	port(
		clk         	: in sl;
		rst				: in sl;
	    tx				: out sl;
		--AXI
        mAxisClk        : in  sl;
        mAxisRst        : in  sl;
        mAxisMaster     : in AxiStreamMasterType;
        mAxisSlave      : out  AxiStreamSlaveType);
end entity Serializer;

architecture Behavioral of Serializer is

	signal dinFrameDetect		: slv(7 downto 0);
	signal dinFrameDetectValid	: sl;
	signal doutFrameDetect		: slv(7 downto 0);
	signal doutFrameDetectValid	: sl;

	signal uartWrData			: slv(7 downto 0);
	signal uartWrValid			: sl;
	signal uartWrReady          : sl;

begin

------------------------------------------------------------------------------------------------
-- Detect start (0xC0) and stop (0xFF) frame. Also remove src and dst id from data.
------------------------------------------------------------------------------------------------
   dinFrameDetect		<= mAxisMaster.tData(7 downto 0);
   dinFrameDetectValid	<= mAxisMaster.tValid;
   U_FrameDetect : entity work.FrameDetect
      generic map (
         TPD_G             => TPD_G)
      port map (
         -- Clock and Reset
         clk     	=> clk,
         rst     	=> rst,
         -- Data Interface
         din	 	=> dinFrameDetect,
		 dinValid	=> dinFrameDetectValid,
		 dout		=> doutFrameDetect,
		 doutValid	=> doutFrameDetectValid);

------------------------------------------------------------------------------------------------
-- UART core
------------------------------------------------------------------------------------------------
   uartWrData	        <= doutFrameDetect;
   uartWrValid	        <= doutFrameDetectValid;
   mAxisSlave.tReady    <= uartWrReady;
   U_Uart : entity surf.UartWrapper
      generic map (
         TPD_G             => TPD_G,
         CLK_FREQ_G        => CLK_FREQ_G,
         BAUD_RATE_G       => BAUD_RATE_G,
         MEMORY_TYPE_G     => MEMORY_TYPE_G,
         FIFO_ADDR_WIDTH_G => FIFO_ADDR_WIDTH_G)
      port map (
         -- Clock and Reset
         clk     => clk,
         rst     => rst,
         -- Write Interface
         wrData  => uartWrData,
         wrValid => uartWrValid,
         wrReady => uartWrReady,
         -- Read Interface
         rdData  => open,
         rdValid => open,
         rdReady => '0',
         -- UART Serial Interface
         tx      => tx,
         rx      => '1');

end Behavioral;

