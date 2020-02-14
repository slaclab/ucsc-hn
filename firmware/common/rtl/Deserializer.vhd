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
use work.SapetPacketPkg.all;

entity Deserializer is
	generic(
		TPD_G			: time		:= 1 ns);
	port(
		rst         	: in sl;
		clk				: in sl;
		boardid			: in slv(2 downto 0);
		rx				: in sl;
		outDataValid	: out sl;
		outData			: out slv(15 downto 0));
end entity Deserializer;

architecture Behavioral of Deserializer is

	type DeserializerStateType is ( 
		IDLE_S, 
		FIRST_WORD_S, 
		SECOND_WORD_S, 
		OTHER_WORD_S);
		
	type DeserializerSubStateType is (
		FIRST_BYTE_S, 
		SECOND_BYTE_S, 
		OTHER_BYTE_S,
		END_OF_FRAME_CHECK_0_S,
		END_OF_FRAME_CHECK_1_S,
		WAIT_0_S,
		WAIT_1_S );
		
	type RegType is record
		deserializerState		: DeserializerStateType;
		deserializerSubState	: DeserializerSubStateType;
		deserialData			: slv(15 downto 0);
		deserialDataValid		: sl;
		bitInByte				: slv(7 downto 0);	
	end record RegType;
	
	constant REG_INIT_C : RegType := (
		deserializerState		=> IDLE_S,
		deserializerSubState	=> FIRST_BYTE_S,
		deserialData			=> (others => '0'),
		deserialDataValid		=> '0',
		bitInByte				=> (others => '0') );
	
	signal r	: RegType := REG_INIT_C;
	signal rin	: RegType;


begin

	comb : process(r, rx, rst) is
		variable v : RegType;
	
	begin
	-- {
		-- Latch the current value
		v 					:= r;
		v.deserialDataValid	:= '0';
		
		-- NOTE: The state names FIRST_BYTE_S, FIRST_WORD_S etc. refers to the order of operation rather than the structure of the data
		case r.deserializerState is
			when IDLE_S =>
				v.deserialData 				:= x"0000";
				v.bitInByte					:= x"00";
				-- Wait for start rx line to go LOW to indicate start
				if (rx = '0') then
					v.deserializerState		:= FIRST_WORD_S;
					v.deserializerSubState	:= FIRST_BYTE_S;
				end if;
			
			-- The first 16 bits received contain the packet start token and the source node (board id)
			when FIRST_WORD_S =>
				case r.deserializerSubState is
					when FIRST_BYTE_S =>
						-- Shift rx data into deserialData until the first byte is filled
						v.deserialData(15 downto 8) := rx & r.deserialData(15 downto 9);
						v.bitInByte 				:= r.bitInByte + 1;
						if (r.bitInByte = 7) then
							v.deserializerSubState 	:= SECOND_BYTE_S;
						end if;
						
					when SECOND_BYTE_S =>
						-- Disregard the rx line for 1 clock cycle
						-- First byte received has to be a start token
						if is_packet_start_token(r.deserialData(15 downto 8)) then
							-- Add ID of the src node to the data
							v.deserialData(7 downto 0) 	:= "00000" & boardid;
							v.deserialDataValid			:= '1';
							v.deserializerSubState		:= WAIT_0_S;
						else
						-- If first byte is not start token, discard and wait for next transaction
							v.deserialData 			:= x"0000";
							v.deserializerState		:= IDLE_S;
						end if;
						
					when WAIT_0_S =>
						v.deserialData	:= x"0000";
						-- wait for rx to go low again to signal start
						if (rx = '0') then
							v.deserializerState		:= SECOND_WORD_S;
							v.bitInByte				:= x"00";
							v.deserializerSubState	:= FIRST_BYTE_S;
						end if;
						
					when others =>
						v.deserialData			:= x"0000";
						v.deserializerState 	:= IDLE_S;
						v.deserializerSubState	:= FIRST_BYTE_S;

				end case;

			-- The next 16 bits contain the destination (PC node) and the Rena Board ID
			when SECOND_WORD_S =>
				case r.deserializerSubState is
					when FIRST_BYTE_S =>
						-- Shift rx data into deserialData until the first byte is filled
						v.deserialData(7 downto 0)	:= rx & r.deserialData(7 downto 1);
						v.bitInByte 				:= r.bitInByte + 1;
						if (r.bitInByte = 7) then
							v.deserializerSubState 	:= SECOND_BYTE_S;
						end if;
					
					when SECOND_BYTE_S =>
						-- Disregard the rx line for 1 clock cycle
						-- Add the destination ID (PC -> node0 -> x"00")
						v.deserialData(15 downto 8) := x"00";
						v.deserialDataValid			:= '1';
						v.deserializerSubState		:= WAIT_0_S;
											
					when WAIT_0_S =>
						v.deserialData	:= x"0000";
						-- wait for rx to go low again to signal start
						if (rx = '0') then
							v.deserializerState		:= OTHER_WORD_S;
							v.bitInByte				:= x"00";
							v.deserializerSubState	:= FIRST_BYTE_S;
						end if;
						
					when others =>
						v.deserialData			:= x"0000";
						v.deserializerState 	:= IDLE_S;
						v.deserializerSubState	:= FIRST_BYTE_S;
					
					end case;
			
			-- The rest of the data (time, channel, ADC values, etc)
			when OTHER_WORD_S =>
				case r.deserializerSubState is
					when FIRST_BYTE_S =>
						-- Shift rx data into deserialData until the first byte is filled
						v.deserialData(15 downto 8) := rx & r.deserialData(15 downto 9);
						v.bitInByte 				:= r.bitInByte + 1;
						if (r.bitInByte = 7) then
							v.deserializerSubState 	:= END_OF_FRAME_CHECK_0_S;
						end if;
					
					when END_OF_FRAME_CHECK_0_S =>
						-- Disregard the rx line for 1 clock cycle
						-- If end of frame 0xFF detected, finish transaction early and wait for new data
						if (r.deserialData(15 downto 8) = x"FF") then
							v.deserialData := x"FF00";
							v.deserialDataValid	:= '1';
							v.deserializerState := IDLE_S;
						else
							v.deserializerSubState := WAIT_0_S;
						end if;
					
					when WAIT_0_S =>
						-- Wait for rx to go low again to signal start
						if (rx = '0') then
							v.bitInByte				:= x"00";
							v.deserializerSubState	:= SECOND_BYTE_S;
						end if;
					
					when SECOND_BYTE_S =>
						-- Shift rx data into deserialData until the first byte is filled
						v.deserialData(7 downto 0)	:= rx & r.deserialData(7 downto 1);
						v.bitInByte 				:= r.bitInByte + 1;
						if (r.bitInByte = 7) then
							v.deserializerSubState 	:= END_OF_FRAME_CHECK_1_S;
						end if;
					
					when END_OF_FRAME_CHECK_1_S =>
						-- Disregard the rx line for 1 clock cycle
						-- If end of frame 0xFF detected, finish transaction and wait for new data
						v.deserialDataValid	:= '1';
						if (r.deserialData(7 downto 0) = x"FF") then
							v.deserializerState := IDLE_S;
						else
							v.deserializerSubState := WAIT_1_S;
						end if;
					
					when WAIT_1_S =>
						-- Wait for rx to go low again to signal start
						if (rx = '0') then
							v.bitInByte				:= x"00";
							v.deserializerSubState	:= FIRST_BYTE_S;
						end if;
						
					when others =>
						v.deserialData			:= x"0000";
						v.deserializerState 	:= IDLE_S;
						v.deserializerSubState	:= FIRST_BYTE_S;

				end case;
				
			when others =>
				v.deserialData			:= x"0000";
				v.deserializerState 	:= IDLE_S;
				v.deserializerSubState	:= FIRST_BYTE_S;
					
		end case;
	
		
		-- Synchronous Reset
		if (rst = '1') then
			v := REG_INIT_C;
		end if;
		
		-- Register the variable for next clock cycle
		rin <= v;
		
		-- Outputs
		outDataValid <= r.deserialDataValid;
		outData		 <= r.deserialData;
			
	end process comb;
	
	seq : process (clk) is
	begin
		if (rising_edge(clk)) then
			r <= rin after TPD_G;
		end if;
	end process seq;
end Behavioral;

