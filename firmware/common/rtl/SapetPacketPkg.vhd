----------------------------------------------------------------------------------
-- Company:      Stanford MIIL (Molecular Imaging Instrumentation Lab)
-- Project:      SAPET - Small Animal PET System
--                - Shared FPGA Code
-- Engineer:     Judson Wilson
--
-- Create Date:    01/15/2014 
-- Design Name:
-- Module Name:    SapetPacketPkg

-- Target Devices:
-- Tool versions:
-- Description:
--     Centralizes various common constants used in the machine.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.ALL;


package SapetPacketPkg is
	constant max_packet_size_bytes : integer := 192;

	constant packet_start_token_frontend_config	    : std_logic_vector(7 downto 0) := x"C0"; -- Originates in PC, goes to Frontend
	constant packet_start_token_frontend_config_echo : std_logic_vector(7 downto 0) := x"C1"; -- Originates in the Daisychain, goes to PC
	constant packet_start_token_frontend_diagnostic  : std_logic_vector(7 downto 0) := x"C4"; -- Originates in Frontend, goes to PC
	constant packet_start_token_data_AND_mode        : std_logic_vector(7 downto 0) := x"C8"; -- Originates in Frontend, goes to PC
	constant packet_start_token_data_OR_mode         : std_logic_vector(7 downto 0) := x"C9"; -- Originates in Frontend, goes to PC
	constant packet_start_token_throughput_test      : std_logic_vector(7 downto 0) := x"CC"; -- Originates in Frontend, goes to PC
	constant packet_end_token  : std_logic_vector(7 downto 0) := x"FF";

	-- Function is_packet_start_byte returns true if the byte is a valid header byte
	-- (the first byte of a packet) otherwise it returns false.
	function is_packet_start_token(B : std_logic_vector(7 downto 0)) return boolean;

	-- Function check_first_packet_word_good returns true if the top byte of W is a valid
	-- start token, and the lower (source) byte is in the inclusive range [R_lowest, R_highest].
	-- Generally you would check the range x"00" to x"04".
	function check_first_packet_word_good (
		W         : std_logic_vector(15 downto 0);
		R_lowest  : std_logic_vector(7 downto 0);
		R_highest : std_logic_vector(7 downto 0)
		) return boolean;

	-- Function check_first_packet_word_good returns true if the top byte of W is a valid
	-- start token, and the lower (source) byte is in the inclusive range [R_lowest, R_highest].
	-- Generally you would check the range x"00" to x"04".
	function word_contains_packet_end_token (W : std_logic_vector(15 downto 0)) return boolean;

end;

package body SapetPacketPkg is

	-- constant max_packet_size_byes : integer := todo fixme

	function is_packet_start_token(B : std_logic_vector(7 downto 0)) return boolean is
	begin
		return  B = packet_start_token_frontend_config
		     or B = packet_start_token_frontend_config_echo
		     or B = packet_start_token_frontend_diagnostic
		     or B = packet_start_token_data_AND_mode
		     or B = packet_start_token_data_OR_mode
		     or B = packet_start_token_throughput_test;
	end is_packet_start_token;
	

	function check_first_packet_word_good (
		W         : std_logic_vector(15 downto 0);
		R_lowest  : std_logic_vector(7 downto 0);
		R_highest : std_logic_vector(7 downto 0)
		) return boolean is
	begin
		return is_packet_start_token(W(15 downto 8))
		   and unsigned(W(7 downto 0)) >= unsigned(R_lowest)
			and unsigned(W(7 downto 0)) <= unsigned(R_highest);
	end check_first_packet_word_good;


	function word_contains_packet_end_token (W : std_logic_vector(15 downto 0)) return boolean is
	begin
		return W(15 downto 8) = packet_end_token or W(7 downto 0) = packet_end_token;
	end word_contains_packet_end_token;

end package body;