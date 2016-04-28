---------------------------------------------------------------------------------------
-- Company: Digilent Inc.
-- Engineer: Josh Sackos
-- 
-- Create Date:    07/11/2012
-- Module Name:    PmodJSTK_Demo 
-- Project Name: 	 PmodJSTK_Demo
-- Target Devices: Nexys3
-- Tool versions:  ISE 14.1
-- Description: This is a demo for the Digilent PmodJSTK. Data is sent and received
--					 to and from the PmodJSTK at a frequency of 1kHz, and positional 
--					 data is displayed on the seven segment display (SSD). The positional
--					 data of the joystick ranges from 0 to 1023 in both the X and Y
--					 directions. Only one coordinate can be displayed on the SSD at a
--					 time, therefore switch SW0 is used to select which coordinate's data
--	   			 to display. Postional data displayed on the SSD will be updated at a
--					 frequency of 5Hz. The status of the buttons on the PmodJSTK are
--					 displayed on LD2, LD1, and LD0 on the Nexys3. The LEDs will
--					 illuminate when a button is pressed. Switches SW2 adn SW1 on the
--					 Nexys3 will turn on LD1 and LD2 on the PmodJSTK respectively. Button
--					 BTND on the Nexys3 is used for reseting the demo. The PmodJSTK
--					 connects to pins [4:1] on port JA on the Nexys3. SPI mode 0 is used
--					 for communication between the PmodJSTK and the Nexys3.
--
--					 NOTE: The digits on the SSD may at times appear to flicker, this
--						    is due to small pertebations in the positional data being read
--							 by the PmodJSTK's ADC. To reduce the flicker simply reduce
--							 the rate at which the data being displayed is updated.
--
-- Revision History: 
-- 						Revision 0.01 - File Created (Josh Sackos)
---------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


--  ===================================================================================
--  								Define Module, Inputs and Outputs
--  ===================================================================================
entity PmodJSTK_Master is
    Port ( clk : in  STD_LOGIC;								-- 100Mhz onboard clock
           RST : in  STD_LOGIC;								-- Button D
           MISO : in  STD_LOGIC;							-- Master In Slave Out, JA3
           SW : in  STD_LOGIC_VECTOR (2 downto 0);			-- Switches 2, 1, and 0
           SS : out  STD_LOGIC;								-- Slave Select, Pin 1, Port JA
           MOSI : out  STD_LOGIC;							-- Master Out Slave In, Pin 2, Port JA
           SCLK : out  STD_LOGIC;							-- Serial Clock, Pin 4, Port JA
           LED : out  STD_LOGIC_VECTOR (7 downto 0);		-- LEDs 7 to 0
		   intr : out STD_LOGIC;
		   pos : out STD_LOGIC_VECTOR(1 downto 0));
end PmodJSTK_Master;

architecture Behavioral of PmodJSTK_Master is

--  ===================================================================================
-- 							  					Components
--  ===================================================================================

		-- **********************************************
		-- 					SPI Interface
		-- **********************************************
		component PmodJSTK

			 Port (   clk : in  STD_LOGIC;
					  RST : in  STD_LOGIC;
					  sndRec : in  STD_LOGIC;
					  DIN : in  STD_LOGIC_VECTOR (7 downto 0);
					  MISO : in  STD_LOGIC;
					  SS : out  STD_LOGIC;
					  SCLK : out  STD_LOGIC;
					  MOSI : out  STD_LOGIC;
					  DOUT : inout  STD_LOGIC_VECTOR (39 downto 0)
			 );

		end component;


		-- **********************************************
		-- 				5Hz Clock Divider
		-- **********************************************
		component ClkDiv_5Hz

			 Port ( clk : in  STD_LOGIC;
					  RST : in  STD_LOGIC;
					  CLKOUT : inout STD_LOGIC
			 );

		end component;


--  ===================================================================================
-- 							  			Signals and Constants
--  ===================================================================================

			-- Holds data to be sent to PmodJSTK
			signal sndData : STD_LOGIC_VECTOR(7 downto 0) := X"00";

			-- Signal to send/receive data to/from PmodJSTK
			signal sndRec : STD_LOGIC;

			-- Signal indicating that SPI interface is busy
			signal BUSY : STD_LOGIC := '0';

			-- Data read from PmodJSTK
			signal jstkData : STD_LOGIC_VECTOR(39 downto 0) := (others => '0');

			-- Signal carrying output data that user selected
			--signal posData : STD_LOGIC_VECTOR(9 downto 0);

			signal xposData : STD_LOGIC_VECTOR(9 downto 0);
			signal yposData : STD_LOGIC_VECTOR(9 downto 0);
			
			
--  ===================================================================================
-- 							  				Implementation
--  ===================================================================================
begin

			-------------------------------------------------
			--  	  			PmodJSTK Interface
			------------------------------------------------
			PmodJSTK_Int : PmodJSTK port map(
					clk=>clk,
					RST=>RST,
					sndRec=>sndRec,
					DIN=>sndData,
					MISO=>MISO,
					SS=>SS,
					SCLK=>SCLK,
					MOSI=>MOSI,
					DOUT=>jstkData
			);
			
			
			
			-------------------------------------------------
			--  		 Send Receive Signal Generator
			-------------------------------------------------
			genSndRec : ClkDiv_5Hz port map(
					clk=>clk,
					RST=>RST,
					CLKOUT=>sndRec
			);



			-- Use state of switch 0 to select output of X position or Y position data to SSD
			-- posData <= (jstkData(9 downto 8) & jstkData(23 downto 16)) when (SW(0) = '1') else (jstkData(25 downto 24) & jstkData(39 downto 32));

			xposData <= (jstkData(9 downto 8) & jstkData(23 downto 16));

			yposData <= (jstkData(25 downto 24) & jstkData(39 downto 32));

			--process(sndRec, xposData, RST) begin
			--	if(RST = '1') then
			--		pos <= "00";
			--	elsif rising_edge(clk) then
			--		if sndRec = '1' then
			--			if xposData <= "1010111100" then
			--				pos <= "00"; 						--höger
			--				intr <= '1';
			--			elsif xposData >= "0100101100" then
			--				pos <= "01"; 						--vänster
			--				intr <= '1';
			--			end if;
			--		else 
			--			intr <= '0';
			--		end if;
			--	end if;
			--end process;

			process(sndRec, yposData, RST, clk) begin
				if(RST = '1') then
					pos <= "00";
				elsif rising_edge(clk) then
					if sndRec = '1' then
						if yposData >= "1010001010" then
							pos <= "10"; 						--upp
							intr <= '1';
						elsif yposData <= "0101011110" then
							pos <= "11"; 						--ner
							intr <= '1';
						elsif xposData <= "0101011110" then
							pos <= "00"; 						--höger
							intr <= '1';
						elsif xposData >= "1010001010" then
							pos <= "01"; 						--vänster
							intr <= '1';
						end if;
					else
						intr <= '0';
					end if;
				--else
					--yPos <= "00";
				end if;
			end process;

			-- LED <= ("000000" & pos);

			-- väljer antingen x eller y värden som ska visas beroende på vilken knapp som trycks ner på joysticken
			--process(sndRec) begin
				--if(RST = '1') then
					--LED <= "00000000";
				--if sndRec = '1' and jstkData(1) = '1' then
				--	LED <= xposData(7 downto 0);
				--elsif sndRec = '1' and jstkData(0) = '1' then
				--	LED <= yposData(7 downto 0);
				--end if;
			--end process;

			--posData <= (jstkData(25 downto 24) & jstkData(39 downto 32));

			-- Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
			sndData <= "100000" & SW(1) & SW(2);

			-- Assign PmodJSTK button status to LED[2:0]
			--process(sndRec, RST) begin
			--		if(RST = '1') then
			--				LED <= "000";
			--		elsif sndRec = '1' then
			--				--LED <= jstkData(1) & jstkData(2) & jstkData(0);
			--				ledData <= jstkData(1) & jstkData(2) & jstkData(0);
			--		end if;
			--end process;

end Behavioral;

