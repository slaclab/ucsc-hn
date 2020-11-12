-------------------------------------------------------------------------------
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Creates AXI accessible registers containing configuration
-- information.
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library surf;
use surf.StdRtlPkg.all;
use surf.AxiLitePkg.all;

entity FanInRegs is
   generic (
      TPD_G : time := 1 ns);
   port (

      -- AXI-Lite Interface
      axiClk         : in    sl;
      axiRst         : in    sl;
      axiReadMaster  : in    AxiLiteReadMasterType;
      axiReadSlave   : out   AxiLiteReadSlaveType;
      axiWriteMaster : in    AxiLiteWriteMasterType;
      axiWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Values
      syncPb     : in  sl;
      syncReg    : out sl;
      syncIn     : in  sl;
      fpgaProgL  : out sl;
      rxEnable   : out slv(30 downto 1);
      currRxData : in  slv(30 downto 1);
      countRst   : out sl;
      rxPackets  : in  Slv32Array(30 downto 1);
      dropBytes  : in  Slv32Array(30 downto 1));

end FanInRegs;

architecture rtl of FanInRegs is

   type RegType is record
      countRst       : sl;
      syncRegCnt     : slv(3 downto 0);
      syncReg        : sl;
      syncDet        : sl;
      fpgaProg       : sl;
      rxEnable       : slv(30 downto 1);
      axiReadSlave   : AxiLiteReadSlaveType;
      axiWriteSlave  : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      countRst       => '0',
      syncRegCnt     => (others=>'0'),
      syncReg        => '0',
      syncDet        => '0',
      fpgaProg       => '0',
      rxEnable       => (others=>'0'),
      axiReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axiWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process (r, axiReadMaster, axiRst, axiWriteMaster, rxPackets, dropBytes, currRxData, syncIn, syncPb) is
      variable v      : RegType;
      variable axilEp : AxiLiteEndpointType;
   begin

      -- Latch the current value
      v := r;

      v.countRst := '0';
      v.syncDet := '0';

      if r.syncDet = '1' then
         v.syncRegCnt := (others=>'1');
         v.syncReg := '1';
      elsif v.syncRegCnt = 0 then
         v.syncReg := '0';
      else
         v.syncRegCnt := r.syncRegCnt - 1;
      end if;

      ------------------------
      -- AXI-Lite Transactions
      ------------------------

      -- Determine the transaction type
      axiSlaveWaitTxn(axilEp, axiWriteMaster, axiReadMaster, v.axiWriteSlave, v.axiReadSlave);

      axiSlaveRegister(axilEp, x"004", 1, v.rxEnable);
      axiSlaveRegisterR(axilEp, x"008", 1, currRxData);
      axiWrDetect(axilEp, x"00C", v.countRst);
      axiWrDetect(axilEp, x"010", v.syncReg);
      axiSlaveRegisterR(axilEp, x"014", 0, syncIn);
      axiSlaveRegisterR(axilEp, x"014", 1, syncPb);
      axiSlaveRegister(axilEp, x"018", 0, v.fpgaProg);

      -- Rx Packet Registers, 0x100 - 0x174
      for i in 1 to 30 loop
         axiSlaveRegisterR(axilEp, toSlv(256 + (i-1)*4,12), 0, rxPackets(i));
      end loop;

      -- Rx Drop Bytes Registers, 0x200 - 0x274
      for i in 1 to 30 loop
         axiSlaveRegisterR(axilEp, toSlv(512 + (i-1)*4,12), 0, dropBytes(i));
      end loop;

      -- Close the transaction
      axiSlaveDefault(axilEp, v.axiWriteSlave, v.axiReadSlave, AXI_RESP_DECERR_C);

      --------
      -- Reset
      --------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      axiReadSlave   <= r.axiReadSlave;
      axiWriteSlave  <= r.axiWriteSlave;
      countRst       <= r.countRst;
      rxEnable       <= r.rxEnable;
      syncReg        <= r.syncReg;

      if r.fpgaProg = '1' then
         fpgaProgL <= '0';
      else
         fpgaProgL <= 'Z';
      end if;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end architecture rtl;
