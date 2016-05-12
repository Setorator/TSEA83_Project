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
use IEEE.STD_LOGIC_UNSIGNED.ALL;


--  ===================================================================================
--  								Define Module, Inputs and Outputs
--  ===================================================================================
entity PmodJSTK_Master is
    Port ( clk : in  STD_LOGIC;											-- 100Mhz onboard clock
           rst : in  STD_LOGIC;											-- Button D
           MISO : in  STD_LOGIC;											-- Master In Slave Out, JA3
	   	  joystick_pos : buffer unsigned(1 downto 0);				-- positionen som joysticken är i
	   	  start_pacman : out std_logic;
           SS : out  STD_LOGIC;											-- Slave Select, Pin 1, Port JA
           MOSI : out  STD_LOGIC;										-- Master Out Slave In, Pin 2, Port JA
           SCLK : out  STD_LOGIC											-- Serial Clock, Pin 4, Port JA
           );	


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
					  rst : in  STD_LOGIC;
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
					  rst : in  STD_LOGIC;
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

			signal xPos : STD_LOGIC_VECTOR(1 downto 0) := "01";
			signal yPos : STD_LOGIC_VECTOR(1 downto 0) := "01";
			
--  ===================================================================================
-- 							  				Implementation
--  ===================================================================================
begin


			-------------------------------------------------
			--  	  			PmodJSTK Interface
			------------------------------------------------
			PmodJSTK_Int : PmodJSTK port map(
					clk=>clk,
					rst=>rst,
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
					rst=>rst,
					CLKOUT=>sndRec
			);



			xPos <= jstkData(25 downto 24);
			yPos <= jstkData(9 downto 8);
			

			process(clk) 
			begin
				if rising_edge(clk) then
					if(rst = '1') then		
						joystick_pos <= "10";
						start_pacman <= '0'; 
					elsif xPos = "11" and joystick_pos /= "10" then
						start_pacman <= '1';
						joystick_pos <= "10";					-- höger
					elsif yPos = "11" and joystick_pos /= "01" then	
						start_pacman <= '1';
						joystick_pos <= "01";					-- upp
					elsif xPos = "00" and joystick_pos /= "00" then	
						start_pacman <= '1';
						joystick_pos <= "00";					-- vänster
					elsif yPos = "00" and joystick_pos /= "11" then	
						start_pacman <= '1';
						joystick_pos <= "11";					-- ner
					else
						start_pacman <= '0';
					end if;
				end if;
			end process;

 
			-- Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
			sndData <= "10000000";

end Behavioral;

