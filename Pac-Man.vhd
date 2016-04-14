-------------------------------------------------------------------------------
-- Top module for our project
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations

-- entity
entity Pac-Man is
  
  port (
    clk            : in std_logic;                         -- system clock
    rst            : in std_logic;                         -- reset button
    video          : out std_logic_vector(7 downto 0);     -- RGB-signal
                                                           -- to monitor
         );
    
end Pac-Man;

-- architecture
architecture Behavioral of PIX_GEN is

  component PIX_GEN
    port (
      clk                    : in std_logic;                      -- System clock
      clk25                    : in std_logic;                    -- 25 MHz 
      pixel                  : out std_logic_vector(7 downto 0);  -- colour to
                                                                  -- be sent
                                                                  -- to VGA_MOTOR
      colision               : out std_logic;                     -- Used
                                                                  -- for interupts
         );
      
  end component;

  component VGA_MOTOR
    port (
      clk                    : in std_logic;                      -- System clock
      clk25                  : in std_logic;                      -- 25 MHz
      rst                    : in std_logic;                      -- reset button
      Hsync                  : out std_logic;                     -- horizontal sync
      Vsync                  : out std_logic;                     -- vertical sync
      vgaRed                 : out std_logic_vector(2 downto 0);  -- VGA red
      vgaGreen               : out std_logic_vector(2 downto 0);  -- VGA green
      vgaBlue                : out std_logic_vector(2 downto 1);  -- VGA blue
         );
  end component;

  signal ClkDiv	        : unsigned(1 downto 0);	 -- Clock divisor, to generate
                                                 -- 25 MHz clock
  signal Clk25		: std_logic;		 -- One pulse width 25 MHz sign

begin 

  
  -- Clock divisor
  -- divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
	ClkDiv <= (others => '0');
      else
	ClkDiv <= ClkDiv + 1;
      end if;
    end if;
  end process;
  -- 25 MHz clock (one system clock pulse width)
  Clk25 <= '1' when (ClkDiv = 3) else '0';

  process(clk)
  begin

  
end Behavioral;
