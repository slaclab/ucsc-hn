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

entity Deserializer is
   generic(
      TPD_G         : time                := 1 ns;
      TDEST_G       : natural             := 0;
      AXIS_CONFIG_G : AxiStreamConfigType := AXI_STREAM_CONFIG_INIT_C
      );
   port(

      -- Input
      sysClk    : in sl;
      sysClkRst : in sl;
      rx        : in sl;

      -- Counters
      countRst   : in  sl;
      rxEnable   : in  sl;
      currRxData : out sl;
      rxPackets  : out slv(31 downto 0);
      dropBytes  : out slv(31 downto 0);

      -- Output
      mAxisClk    : in  sl;
      mAxisRst    : in  sl;
      mAxisMaster : out AxiStreamMasterType;
      mAxisSlave  : in  AxiStreamSlaveType);

end entity Deserializer;

architecture Behavioral of Deserializer is

   constant MAX_FRAME_C : integer := 1024;

   constant packet_start_token_frontend_diagnostic  : std_logic_vector(7 downto 0) := x"C4";  -- Originates in Frontend, goes to PC
   constant packet_start_token_data_AND_mode        : std_logic_vector(7 downto 0) := x"C8";  -- Originates in Frontend, goes to PC
   constant packet_start_token_data_OR_mode         : std_logic_vector(7 downto 0) := x"C9";  -- Originates in Frontend, goes to PC

   -- Function is_packet_start_byte returns true if the byte is a valid header byte
   -- (the first byte of a packet) otherwise it returns false.
   function is_packet_start_token(B : std_logic_vector(7 downto 0)) return boolean is
   begin
      return B = packet_start_token_frontend_diagnostic
         or B = packet_start_token_data_AND_mode
         or B = packet_start_token_data_OR_mode;
   end is_packet_start_token;

   constant INT_AXIS_CONFIG_C : AxiStreamConfigType := (
      TSTRB_EN_C    => AXIS_CONFIG_G.TSTRB_EN_C,
      TDATA_BYTES_C => 1, -- 8-bit data width (1 byte)
      TDEST_BITS_C  => AXIS_CONFIG_G.TDEST_BITS_C,
      TID_BITS_C    => AXIS_CONFIG_G.TID_BITS_C,
      TKEEP_MODE_C  => AXIS_CONFIG_G.TKEEP_MODE_C,
      TUSER_BITS_C  => AXIS_CONFIG_G.TUSER_BITS_C,
      TUSER_MODE_C  => AXIS_CONFIG_G.TUSER_MODE_C);

   type StateType is (
      IDLE_S,
      DATA_S);

   type RegType is record
      state         : StateType;
      uartRd        : sl;
      rxPackets     : slv(31 downto 0);
      dropBytes     : slv(31 downto 0);
      dropCntEn     : sl;
      timeoutCnt    : slv(23 downto 0);
      timeoutRst    : sl;
      timeout       : sl;
      count         : slv(31 downto 0);
      intAxisMaster : AxiStreamMasterType;
      regAxisMaster : AxiStreamMasterType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      state         => IDLE_S,
      uartRd        => '0',
      rxPackets     => (others => '0'),
      dropBytes     => (others => '0'),
      dropCntEn     => '0',
      timeoutCnt    => (others => '1'),
      timeoutRst    => '0',
      timeout       => '0',
      count         => (others => '0'),
      intAxisMaster => axiStreamMasterInit(INT_AXIS_CONFIG_C),
      regAxisMaster => axiStreamMasterInit(INT_AXIS_CONFIG_C));

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   signal uartData : slv(7 downto 0);
   signal uartDen  : sl;
   signal uartRd   : sl;

   signal rxTmp : sl;
   signal rxInt : sl;

   signal txAxisMaster : AxiStreamMasterType;
   signal txAxisSlave  : AxiStreamSlaveType;

   signal countRstReg : sl;
   signal rxEnableReg : sl;

begin

   currRxData <= rxTmp;

   U_SyncEnable: entity surf.Synchronizer
      generic map ( TPD_G          => TPD_G )
      port map (
         clk     => sysClk,
         rst     => sysClkRst,
         dataIn  => rxEnable,
         dataOut => rxEnableReg);

   U_SyncCntRst: entity surf.Synchronizer
      generic map ( TPD_G => TPD_G )
      port map (
         clk     => sysClk,
         rst     => sysClkRst,
         dataIn  => countRst,
         dataOut => countRstReg);

   process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         if sysClkRst = '1' then
            rxTmp <= '0' after TPD_G;
            rxInt <= '0' after TPD_G;
         else
            rxTmp <= rx after TPD_G;
            rxInt <= rxTmp and rxEnableReg after TPD_G;
         end if;
      end if;
   end process;

   -- Receiving UART
   U_UartRx : entity surf.UartRx
      generic map (
         TPD_G        => TPD_G,
         PARITY_G     => "NONE",
         BAUD_MULT_G  => 4,
         DATA_WIDTH_G => 8
      ) port map (
         clk        => sysClk,
         rst        => sysClkRst,
         baudClkEn  => '1',
         rdData     => uartData,
         rdValid    => uartDen,
         rdReady    => uartRd,
         rx         => rxInt);


   comb : process(r, uartData, uartDen, sysClkRst, countRstReg) is
      variable v : RegType;
   begin

      v := r;

      v.intAxisMaster.tValid := '0';
      v.intAxisMaster.tLast  := '0';
      v.intAxisMaster.tDest  := toSlv(TDEST_G,8);
      v.uartRd    := '0';
      v.dropCntEn := '0';

      if r.timeoutRst = '1' then
         v.timeoutCnt := (others=>'1');
         v.timeout    := '0';
      elsif r.timeoutCnt = 0 then
         v.timeout    := '1';
      else
         v.timeoutCnt := r.timeoutCnt - 1;
      end if;

      if countRstReg = '1' then
         v.rxPackets := (others => '0');
         v.dropBytes := (others => '0');
      end if;

      if r.dropCntEn = '1' then
         v.dropBytes := r.dropBytes + 1;
      end if;

      case r.state is

         when IDLE_S =>
            v.uartRd                          := '1';
            v.intAxisMaster.tData(7 downto 0) := uartData;
            v.timeoutRst := '1';

            if uartDen = '1' then
               if is_packet_start_token(uartData) then
                  v.intAxisMaster.tValid := '1';
                  v.count := r.count + 1;
                  v.state := DATA_S;
               else
                  v.dropCntEn := '1';
               end if;
            end if;

         when DATA_S =>
            v.uartRd                          := '1';
            v.intAxisMaster.tData(7 downto 0) := uartData;
            v.intAxisMaster.tValid            := uartDen;

            if uartDen = '1' and uartData = x"FF" then
               v.intAxisMaster.tLast := '1';
               v.rxPackets := r.rxPackets + 1;
               v.count     := (others=>'0');
               v.state     := IDLE_S;
            elsif r.count = MAX_FRAME_C then
               v.intAxisMaster.tValid := '1';
               v.intAxisMaster.tLast := '1';
               v.state    := IDLE_S;
            elsif v.timeout = '1' then
               v.intAxisMaster.tValid := '1';
               v.intAxisMaster.tLast := '1';
               v.state    := IDLE_S;
            end if;

         when others =>
            v.state := IDLE_S;
      end case;

      regAxisMaster <= intAxisMaster;

      uartRd    <= v.uartRd;
      rxPackets <= r.rxPackets;
      dropBytes <= r.dropBytes;

      -- Synchronous Reset
      if (sysClkRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

   end process comb;

   seq : process (sysClk) is
   begin
      if (rising_edge(sysClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   U_AxiFifo : entity surf.AxiStreamFifoV2
      generic map (
         TPD_G               => TPD_G,
         SLAVE_READY_EN_G    => false,
         GEN_SYNC_FIFO_G     => false,
         FIFO_ADDR_WIDTH_G   => 9,
         VALID_THOLD_G       => 128,  -- Hold until enough to burst into the interleaving MUX
         VALID_BURST_MODE_G  => true,
         SLAVE_AXI_CONFIG_G  => INT_AXIS_CONFIG_C,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_G
      ) port map (
         sAxisClk    => sysClk,
         sAxisRst    => sysClkRst,
         sAxisMaster => r.regAxisMaster,
         mAxisClk    => mAxisClk,
         mAxisRst    => mAxisRst,
         mAxisMaster => txAxisMaster,
         mAxisSlave  => txAxisSlave);

   U_Sof : entity surf.SsiInsertSof
      generic map (
         TPD_G               => TPD_G,
         COMMON_CLK_G        => true,
         SLAVE_FIFO_G        => false,
         MASTER_FIFO_G       => false,
         SLAVE_AXI_CONFIG_G  => AXIS_CONFIG_G,
         MASTER_AXI_CONFIG_G => AXIS_CONFIG_G
      ) port map (
         -- Slave Port
         sAxisClk    => mAxisClk,
         sAxisRst    => mAxisRst,
         sAxisMaster => txAxisMaster,
         sAxisSlave  => txAxisSlave,
         -- Master Port
         mAxisClk    => mAxisClk,
         mAxisRst    => mAxisRst,
         mAxisMaster => mAxisMaster,
         mAxisSlave  => mAxisSlave);

end Behavioral;
