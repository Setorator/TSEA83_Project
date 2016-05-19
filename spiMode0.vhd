--/////////////////////////////////////////////////////////////////////////////////////
-- Company: Digilent Inc.
-- Engineer: Josh Sackos
-- 
-- Create Date:    07/11/2012
-- Module Name:    spiMode0
-- Project Name: 	 PmodJSTK_Demo
-- Target Devices: Nexys3
-- Tool versions:  ISE 14.1
-- Description: This module provides the interface for sending and receiving data
--					 to and from the PmodJSTK, SPI mode 0 is used for communication.  The
--					 master (Nexys3) reads the data on the MISO input on rising edges, the
--					 slave (PmodJSTK) reads the data on the MOSI output on rising edges.
--					 Output data to the slave is changed on falling edges, and input data
--					 from the slave changes on falling edges.
--
--					 To initialize a data transfer between the master and the slave simply
--					 assert the sndRec input.  While the data transfer is in progress the
--					 BUSY output is asserted to indicate to other componenets that a data
--					 transfer is in progress.  Data to send to the slave is input on the 
--					 DIN input, and data read from the slave is output on the DOUT output.
--
--					 Once a sndRec signal has been received five bytes of data will be sent
--					 to the PmodJSTK, and five bytes will be read from the PmodJSTK.  The
--					 data that is sent comes from the DIN input.  For more information on
--					 the contents of the bytes being sent/received see page 2 in the
--					 PmodJSTK reference manual found at the link provided below.
--
--					 http://www.digilentinc.com/Data/Products/XUPV2P-COVERS/PmodJSTK_rm_RevC.pdf
--					 
--					 
--
-- Revision History: 
-- 						Revision 0.01 - File Created (Josh Sackos)
--/////////////////////////////////////////////////////////////////////////////////////
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity spiMode0 is
    Port ( clk : in  std_logic;									-- 100Mhz clock
		   Six_CLK : in std_logic;								-- 66.67khz clock
           rst : in  std_logic;									-- Reset
           sndRec : in  std_logic;								-- Send receive, initializes data read/write
           DIN : in  std_logic_vector (7 downto 0);		-- Data that is to be sent to the slave
           MISO : in  std_logic;									-- Master input slave output
           MOSI : out  std_logic;								-- Master out slave in
           SCLK : out  std_logic;								-- Serial clock
           BUSY : out  std_logic;								-- Busy if sending/receiving data
           DOUT : out  std_logic_vector (7 downto 0));	-- Data read from the slave
end spiMode0;

architecture Behavioral of spiMode0 is
					  
--  ===================================================================================
-- 							  			Signals and Constants
--  ===================================================================================

		-- FSM States
		type state_type is (Idle, Init, RxTx, Done);

		-- Present state, Next State
		signal STATE, NSTATE : state_type;

		signal bitCount : std_logic_vector(3 downto 0) := X"0";				-- Number bits read/written
		signal rSR : std_logic_vector(7 downto 0) := X"00";					-- Read shift register
		signal wSR : std_logic_vector(7 downto 0) := X"00";					-- Write shift register

		signal CE : std_logic := '0';										-- Clock enable, controls serial clock signal sent to slave	
																								

		-- Signals to handle falling and rising edge on the 66.67kHz clock
		signal q : std_logic;
		signal q2 : std_logic;
		signal q2_plus : std_logic;
		signal edge : std_logic;	
		signal edge_down : std_logic;	
		signal edge_up : std_logic;		

--  ===================================================================================
-- 							  				Implementation
--  ===================================================================================
begin	

			process(clk) begin
				if rising_edge(clk) then
					q <= Six_CLK;
				end if;
			end process;

			edge <= '1' when (Six_CLK = '0' and q <= '1') else '0';					-- falling edge on the 66.67kHz clock

			edge_up <= '1' when (Six_CLK = '1' and q <= '0') else '0';					-- rising edge on the 66.67kHz clock

			-- Turns the falling edge signal to a pulse
			process(clk) begin
				if rising_edge(clk) then
					q2 <= q2_plus;
				end if;
			end process;
			q2_plus <= edge;
			edge_down <= ((not q2) and edge);




			-- Serial clock output, allow if clock enable asserted
			SCLK <= Six_CLK when (CE = '1') else '0';
			-- Master out slave in, value always stored in MSB of write shift register
			MOSI <= wSR(7);
			-- Connect data output bus to read shift register
			DOUT <= rSR;
	
			---------------------------------------
			--			 Write Shift Register
			-- 	slave reads on rising edges,
			-- change output data on falling edges
			---------------------------------------
			process(clk) begin
				if rising_edge(clk) then
					if rst = '1' then
							wSR <= X"00";
					
					elsif edge_down = '1' then
							-- Enable shift during RxTx state only
							case(STATE) is
									when Idle =>
											wSR <= DIN;
									
									when Init =>
											wSR <= wSR;
									
									when RxTx =>
											if(CE = '1') then
													wSR <= wSR(6 downto 0) & '0';
											end if;
									
									when Done =>
											wSR <= wSR;
							end case;
					end if;
				end if;
			end process;




			---------------------------------------
			--			 Read Shift Register
			-- 	master reads on rising edges,
			-- slave changes data on falling edges
			---------------------------------------
			process(clk) begin
				if rising_edge(clk) then
					if rst = '1' then
							rSR <= X"00";
					elsif edge_up = '1' then
							-- Enable shift during RxTx state only
							case(STATE) is
									when Idle =>
											rSR <= rSR;
									
									when Init =>
											rSR <= rSR;
									
									when RxTx =>
											if(CE = '1') then
													rSR <= rSR(6 downto 0) & MISO;
											end if;
									
									when Done =>
											rSR <= rSR;
							end case;
					end if;
				end if;
			end process;
			

		--------------------------------
		--		   State Register
		--------------------------------
		STATE_REGISTER: process(clk) begin
			if rising_edge(clk) then
				if rst = '1' then
						STATE <= Idle;
				elsif edge_down = '1' then
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
						CE <= '0';										-- Disable serial clock
						BUSY <= '0';									-- Not busy in Idle state
						bitCount <= X"0";								-- Clear #bits read/written
						
				elsif edge_down = '1' then
						case (STATE) is

								when Idle =>

										CE <= '0';						-- Disable serial clock
										BUSY <= '0';					-- Not busy in Idle state
										bitCount <= X"0";				-- Clear #bits read/written

								when Init =>

										BUSY <= '1';					-- Output a busy signal
										bitCount <= X"0";				-- Have not read/written anything yet
										CE <= '0';						-- Disable serial clock

								when RxTx =>

										BUSY <= '1';					-- Output busy signal
										bitCount <= bitCount + 1;		-- Begin counting bits received/written
										
										-- Have written all bits to slave so prevent another falling edge
										if(bitCount >= X"8") then
												CE <= '0';

										-- Have not written all data, normal operation
										else
												CE <= '1';
										end if;
									
								when Done =>

										CE <= '0';						-- Disable serial clock
										BUSY <= '1';					-- Still busy
										bitCount <= X"0";				-- Clear #bits read/written
								
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
				NSTATE <= Idle;

				case (STATE) is

						when Idle =>
								if sndRec = '1' then
										NSTATE <= Init;
								else
										NSTATE <= Idle;
								end if;

						when Init =>
								NSTATE <= RxTx;

						when RxTx =>
								-- Read last bit so data transmission is finished
								if(bitCount = X"8") then
										NSTATE <= Done;

								-- Data transmission is not finished
								else
										NSTATE <= RxTx;
								end if;
								
						when Done =>
								NSTATE <= Idle;
						when others =>
								NSTATE <= Idle;
				end case;
			end if;      
		end process;

end Behavioral;

