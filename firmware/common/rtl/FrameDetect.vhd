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

entity FrameDetect is
   generic(
      TPD_G            : time := 1 ns;
      REMOVE_SRC_DST_G : sl   := '0');
   port(
      clk       : in  sl;
      rst       : in  sl;
      din       : in  slv(8 downto 0);
      dinValid  : in  sl;
      dout      : out slv(8 downto 0);
      doutValid : out sl);
end entity FrameDetect;

architecture Behavioral of FrameDetect is

   constant packet_start_token_frontend_config : slv(7 downto 0) := x"C0";  -- Originates in PC, goes to Frontend
   constant packet_end_token                   : slv(7 downto 0) := x"FF";  -- Signals end of packet
   
   type StateType is (
      DETECT_START_S,
      THROW_AWAY_S,
      DETECT_END_S);

   type RegType is record
      state     : StateType;
      dout      : slv(7 downto 0);
      doutValid : sl;
      dropByte  : integer range 0 to 3;
   end record RegType;
   
   constant REG_INIT_C : RegType := (
      state     => DETECT_START_S,
      dout      => (others => '0'),
      doutValid => '0',
      dropByte  => 0);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

begin

   comb : process(r, rst, din, dinValid) is
      variable v : RegType;
      
   begin
      -- Latch the current value
      v := r;

      v.doutValid := '0';
      case r.state is
         -- Detect and pass through start of frame 0xC0
         when DETECT_START_S =>
            v.dout := din;
            if (din = packet_start_token_frontend_config and dinValid = '1') then
               v.doutValid := '1';
               if (REMOVE_SRC_DST_G = '1') then
                  v.state := THROW_AWAY_S;
               else
                  v.state := DETECT_END_S;
               end if;
            end if;

            -- Throw away the next two bytes which should be src_id and dst_id;
         when THROW_AWAY_S =>
            if (dinValid = '1') then
               v.dropByte := r.dropByte + 1;
            end if;
            if (r.dropByte = 2) then
               v.dropByte := 0;
               v.state    := DETECT_END_S;
            end if;

            -- Pass through all other data until end of frame of frame 0xFF is detected
         when DETECT_END_S =>
            v.dout      := din;
            v.doutValid := dinValid;
            if (din = packet_end_token) then
               v.state := DETECT_START_S;
            end if;
            
         when others =>
            v.state := DETECT_START_S;
      end case;

      -- Synchronous Reset
      if (rst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
      doutValid <= r.doutValid;
      dout      <= r.dout;
   end process comb;

   seq : process (clk) is
   begin
      if (rising_edge(clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;
end Behavioral;

