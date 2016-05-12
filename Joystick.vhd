library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity Joystick is
    Port ( clk : in  std_logic;								-- 100Mhz onboard clock
           RST : in  std_logic;								-- Button D
           MISO : in  std_logic;								-- Master In Slave Out, JA3
           SW : in  STD_LOGIC_VECTOR (2 downto 0);		-- Switches 2, 1, and 0
           SS : out  std_logic;								-- Slave Select, Pin 1, Port JA
           MOSI : out  std_logic;							-- Master Out Slave In, Pin 2, Port JA
           SCLK : out  STD_LOGIC;							-- Serial Clock, Pin 4, Port JA
           LED : out  STD_LOGIC_VECTOR (2 downto 0);	-- LEDs 2, 1, and 0
           AN : out  STD_LOGIC_VECTOR (3 downto 0);	-- Anodes for Seven Segment Display
           SEG : out  STD_LOGIC_VECTOR (6 downto 0)); -- Cathodes for Seven Segment Display
end Joystick;

architecture Behavioral of Joystick is
