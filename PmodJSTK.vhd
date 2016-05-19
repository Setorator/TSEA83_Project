--//////////////////////////////////////////////////////////////////////////////////////////
-- Company: Digilent Inc.
-- Engineer: Josh Sackos
-- 
-- Create Date:    07/11/2012
-- Module Name:    PmodJSTK
-- Project Name: 	 PmodJSTK_Demo
-- Target Devices: Nexys3
-- Tool versions:  ISE 14.1
-- Description: This component consists of three subcomponents a 66.67kHz serial clock,
--					 a SPI controller and a SPI interface. The SPI interface component is 
--					 responsible for sending and receiving a byte of data to and from the 
--					 PmodJSTK when a request is made. The SPI controller component manages all
--					 data transfer requests, and manages the data bytes being sent to the PmodJSTK.
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
entity PmodJSTK is
    Port ( clk : in  std_logic;
           rst : in  std_logic;
           sndRec : in  std_logic;
           DIN : in  std_logic_vector (7 downto 0);
           MISO : in  std_logic;
           SS : out  std_logic;
           SCLK : out  std_logic;
           MOSI : out  std_logic;
           DOUT : inout  std_logic_vector (39 downto 0));
end PmodJSTK;

architecture Behavioral of PmodJSTK is

-- ====================================================================================
-- 							       		Components
-- ====================================================================================

		-- **********************************************
		-- 					SPI Controller
		-- **********************************************
		component spiCtrl

			 Port (   clk : in  std_logic;
					  Six_CLK : in std_logic;
					  rst : in  std_logic;
					  sndRec : in std_logic;
					  BUSY : in std_logic;
					  DIN : in  std_logic_vector(7 downto 0);
					  RxData : in  std_logic_vector(7 downto 0);
					  SS : out std_logic;
					  getByte : out std_logic;
					  sndData : inout std_logic_vector(7 downto 0);
					  DOUT : inout std_logic_vector(39 downto 0)
			 );

		end component;

		-- **********************************************
		-- 					SPI Interface
		-- **********************************************
		component spiMode0

			 Port (   clk : in  std_logic;
					  Six_CLK : in std_logic;
					  rst : in  std_logic;
					  sndRec : in std_logic;
					  DIN : in  std_logic_vector(7 downto 0);
					  MISO : in  std_logic;
					  MOSI : out std_logic;
					  SCLK : out std_logic;
					  BUSY : out std_logic;
					  DOUT : out std_logic_vector (7 downto 0)
			 );

		end component;


-- ====================================================================================
-- 							       Signals and Constants
-- ====================================================================================

		signal getByte : std_logic;						-- Initiates a data byte transfer in SPI_Int
		signal sndData : std_logic_vector(7 downto 0);	-- Data to be sent to Slave
		signal RxData : std_logic_vector(7 downto 0);	-- Output data from SPI_Int
		signal BUSY : std_logic;						-- Handshake from SPI_Int to SPI_Ctrl


		-- 66.67kHz Clock Divider, period 15us
		signal iSCLK : std_logic;						-- Internal serial clock,
														-- not directly output to slave,
														-- controls state machine, etc.


		-- Value to toggle output clock at
		constant cntEndVal : std_logic_vector(9 downto 0) := "1011101110";	-- End count value
		-- Current count
		signal clkCount : std_logic_vector(9 downto 0) := (others => '0');	-- Stores count value

-- ====================================================================================
-- 							       	 Implementation
-- ====================================================================================
begin

			-------------------------------------------------
			--  	  				SPI Controller
			-------------------------------------------------
			SPI_Ctrl : spiCtrl port map(
					clk=>clk,
					Six_CLK=>iSCLK,
					rst=>rst,
					sndRec=>sndRec,
					BUSY=>BUSY,
					DIN=>DIN,
					RxData=>RxData,
					SS=>SS,
					getByte=>getByte,
					sndData=>sndData,
					DOUT=>DOUT
			);

			-------------------------------------------------
			--  	  				  SPI Mode 0
			-------------------------------------------------
			SPI_Int : spiMode0 port map(
					clk=>clk,
					Six_CLK=>iSCLK,
					rst=>rst,
					sndRec=>getByte,
					DIN=>sndData,
					MISO=>MISO,
					MOSI=>MOSI,
					SCLK=>SCLK,
					BUSY=>BUSY,
					DOUT=>RxData
			);



			-------------------------------------------------
			--	66.67kHz Clock Divider Generates Send/Receive signal
			-------------------------------------------------
			process(clk) begin
				if rising_edge(clk) then
					if rst = '1'  then
						iSCLK <= '0';
						clkCount <= "0000000000";
					elsif(clkCount = cntEndVal) then
						iSCLK <= NOT iSCLK;
						clkCount <= "0000000000";
					else
						clkCount <= clkCount + '1';
					end if;
				end if;

			end process;

			


end Behavioral;

