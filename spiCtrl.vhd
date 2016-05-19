--//////////////////////////////////////////////////////////////////////////////////////////
-- Company: Digilent Inc.
-- Engineer: Josh Sackos
-- 
-- Create Date:    07/11/2012
-- Module Name:    spiCtrl
-- Project Name: 	 PmodJSTK_Demo
-- Target Devices: Nexys3
-- Tool versions:  ISE 14.1
-- Description: This component manages all data transfer requests,
--					 and manages the data bytes being sent to the PmodJSTK.
--
--  				 For more information on the contents of the bytes being sent/received 
--					 see page 2 in the PmodJSTK reference manual found at the link provided
--					 below.
--
--					 http://www.digilentinc.com/Data/Products/XUPV2P-COVERS/PmodJSTK_rm_RevC.pdf
--
-- Revision History: 
-- 						Revision 0.01 - File Created (Josh Sackos)
--//////////////////////////////////////////////////////////////////////////////////////////
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- ====================================================================================
-- 										  Define Module
-- ====================================================================================
entity spiCtrl is
    Port ( clk : in  std_logic;
	   	   Six_CLK : in std_logic;								-- 66.67khz clock
           rst : in  std_logic;
           sndRec : in  std_logic;
           BUSY : in  std_logic;
           DIN : in  std_logic_vector (7 downto 0);
           RxData : in  std_logic_vector (7 downto 0);
           SS : out  std_logic;
           getByte : out  std_logic;
           sndData : inout  std_logic_vector (7 downto 0);
           DOUT : inout  std_logic_vector (39 downto 0));
end spiCtrl;

architecture Behavioral of spiCtrl is

-- ====================================================================================
-- 							       Signals and Constants
-- ====================================================================================

			-- FSM States
			type state_type is (stIdle, stInit, stWait, stCheck, stDone);

			-- Present state, Next State
			signal STATE, NSTATE : state_type;

			signal byteCnt : std_logic_vector(2 downto 0) := "000";					-- Number bits read/written
			constant byteEndVal : std_logic_vector(2 downto 0) := "101";			-- Number of bytes to send/receive
			signal tmpSR : std_logic_vector(39 downto 0) := X"0000000000";			-- Temporary shift register to accumulate all five data bytes

			-- Signals to handle falling edge on the 66.67kHz clock
			signal q : std_logic;
			signal q2 : std_logic;
			signal q2_plus : std_logic;
			signal edge : std_logic;	
			signal edge_down : std_logic;	


-- ====================================================================================
-- 							       	 Implementation
-- ====================================================================================
begin

			
			process(clk) 
			begin
				if rising_edge(clk) then
					q <= Six_CLK;
				end if;
			end process;

			edge <= '1' when (Six_CLK = '0' and q <= '1') else '0';					-- falling edge

			-- Turns the falling edge signal to a pulse
			process(clk) begin
				if rising_edge(clk) then
					q2 <= q2_plus;
				end if;
			end process;
			q2_plus <= edge;
			edge_down <= ((not q2) and edge);


		--------------------------------
		--		   State Register
		--------------------------------
		STATE_REGISTER: process(clk) begin
			if rising_edge(clk) then
				if rst = '1' then
						STATE <= stIdle;
				elsif edge_down = '1' then					-- bytte ut falling_edge(CLK)
						STATE <= NSTATE;
				end if;
			end if;
		end process;

		

		--------------------------------
		--		Output Logic/Assignment
		--------------------------------
		OUTPUT_LOGIC: process (clk) begin
			if rising_edge(clk) then
				if rst = '1' then
						-- Reset/clear values
						SS <= '1';
						getByte <= '0';
						sndData <= X"00";
						tmpSR <= X"0000000000";
						DOUT <= X"0000000000";
						byteCnt <= "000";
						
				elsif edge_down = '1' then					-- bytte ut falling_edge(CLK)
						case (STATE) is

								when stIdle =>

										SS <= '1';												-- Disable slave
										getByte <= '0';										-- Do not request data
										sndData <= X"00";										-- Clear data to be sent
										tmpSR <= X"0000000000";								-- Clear temporary data
										DOUT <= DOUT;											-- Retain output data
										byteCnt <= "000";										-- Clear byte count

								when stInit =>

										SS <= '0';												-- Enable slave
										getByte <= '1';										-- Initialize data transfer
										sndData <= DIN;										-- Store input data to be sent
										tmpSR <= tmpSR;										-- Retain temporary data
										DOUT <= DOUT;											-- Retain output data

										if(BUSY = '1') then
												byteCnt <= byteCnt + '1';	-- Count
										end if;

								when stWait =>

										SS <= '0';												-- Enable slave
										getByte <= '0';										-- Data request already in progress
										sndData <= sndData;									-- Retain input data to send
										tmpSR <= tmpSR;										-- Retain temporary data
										DOUT <= DOUT;											-- Retain output data
										byteCnt <= byteCnt;									-- Count
									
								when stCheck =>

										SS <= '0';												-- Enable slave
										getByte <= '0';										-- Do not request data
										sndData <= sndData;									-- Retain input data to send
										tmpSR <= tmpSR(31 downto 0) & RxData;			-- Store byte just read
										DOUT <= DOUT;											-- Retain output data
										byteCnt <= byteCnt;									-- Do not count

								when stDone =>

										SS <= '1';												-- Disable slave
										getByte <= '0';										-- Do not request data
										sndData <= X"00";										-- Clear input
										tmpSR <= tmpSR;										-- Retain temporary data
										DOUT <= tmpSR;											-- Update output data
										byteCnt <= byteCnt;									-- Do not count
								
						end case;
				end if;
			end if;
		end process;

		--------------------------------
		--		  Next State Logic
		--------------------------------
		NEXT_STATE_LOGIC: process (clk) begin
			if rising_edge(clk) then
				-- Define default state to avoid latches
				NSTATE <= stIdle;

				case (STATE) is

						-- Idle
						when stIdle =>

								-- When send receive signal received begin data transmission
								if sndRec = '1' then
										NSTATE <= stInit;
								else
										NSTATE <= stIdle;
								end if;

						-- Init
						when stInit =>

								if(BUSY = '1') then
										NSTATE <= stWait;
								else
										NSTATE <= stInit;
								end if;
								
						-- Wait
						when stWait =>

								-- Finished reading byte so grab data
								if(BUSY = '0') then
										NSTATE <= stCheck;
								-- Data transmission is not finished
								else
										NSTATE <= stWait;
								end if;
								
						-- Check
						when stCheck =>

								-- Finished reading bytes so done
								if(byteCnt = "101") then
										NSTATE <= stDone;
								-- Have not sent/received enough bytes
								else
										NSTATE <= stInit;
								end if;

						-- Done
						when stDone =>

								-- Wait for external sndRec signal to be de-asserted
								if(sndRec = '0') then
										NSTATE <= stIdle;
								else
										NSTATE <= stDone;
								end if;

						-- Default
--						when others =>
--								NSTATE <= stIdle;
								
				end case;  
			end if;    
		end process;

end Behavioral;

