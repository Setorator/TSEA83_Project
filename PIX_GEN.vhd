library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PIX_GEN is
  
  port (
    clk                    : in std_logic;                      -- System clock
    clk25                  : in std_logic;                      -- 25 MHz

    pixel                  : out std_logic_vector(7 downto 0);  -- colour to
                                                                -- be sent
                                                                -- to VGA_MOTOR
    colision               : out std_logic;                     -- used
                                                                -- for interupts
         );
         
end PIX_GEN;



architecture Behavioral of PIX_GEN is

  signal xPixel         : unsigned(9 downto 0);         -- Horizontal
  
begin





end Behavioral;
	
