library IEEE;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations


-- entity
entity VGA_MOTOR is
  port (
    clk            : in std_logic;                         -- system clock
    clk25          : in std_logic;                         -- 25 MHz

    rst            : in std_logic;                         -- reset
         
    Hsync          : out std_logic;                        -- horizontal sync
    Vsync          : out std_logic;                        -- vertical sync
    vgaRed         : out std_logic_vector(2 downto 0);     -- VGA red
    vgaGreen       : out std_logic_vector(2 downto 0);     -- VGA green
    vgaBlue        : out std_logic_vector(2 downto 1);     -- VGA blue
         );
         
end VGA_MOTOR;


-- architecture
architecture Behavioral of VGA_MOTOR is

  signal Xpixel         : unsigned(9 downto 0);  -- Horizontal pixel counter
  signal Ypixel         : unsigned(9 downto 0);  -- Vertical pixel counter
  signal blank		: std_logic;		 -- blanking signal

begin

  -- Horizontal pixel counter
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        Xpixel <= "0000000000";
      elsif clk25 = '1' then
        if Xpixel = 799 then         -- Counts 0 -> 640+16+96+48 - 1 = 799
          Xpixel <= "0000000000";
        else
          Xpixel <= Xpixel + 1;
        end if;
      end if;
    end if;
  end process;
        
  
  -- Horizontal sync

  process
  begin
    if Xpixel > 655 and Xpixel < 752 then   -- During 96 cycles we should
                                            -- refresh the display. Check the
                                            -- bottom of lab4-PM
      Hsync <= '0';
    else
      Hsync <= '1';
    end if;
  end process;

  
  -- Vertical pixel counter
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        Ypixel <= "0000000000";
      elsif clk25 = '1' and Xpixel = 799 then 
        if Ypixel = 520 then         -- Counts 0 -> 480+10+2+29 - 1 = 520
          Ypixel <= "0000000000";
        else
          Ypixel <= Ypixel + 1;
        end if;
      end if;
    end if;
  end process;
	

  -- Vertical sync

  process
  begin
    if Ypixel > 489 and Ypixel < 492 then
      Vsync <= '0';
    else
      Vsync <= '1';
    end if;
  end process;

  
  -- Video blanking signal

  process
  begin
    if Xpixel > 639 or Ypixel > 479 then
      blank <= '1';
    else
      blank <= '0';
    end if;
  end process;


  -----------------------------------------------------------------------------
  -- Where is our TileMem placed? if it is placed in VGA_MOTOR, there is a
  -- couple of functions to be implemented from ~/TSEA83/VGA_lab/VGA_MOTOR.vhd
  
  -- VGA generation
  --vgaRed(2) 	<= tilePixel(7);
  --vgaRed(1) 	<= tilePixel(6);
  --vgaRed(0) 	<= tilePixel(5);
  --vgaGreen(2)   <= tilePixel(4);
  --vgaGreen(1)   <= tilePixel(3);
  --vgaGreen(0)   <= tilePixel(2);
  --vgaBlue(2) 	<= tilePixel(1);
  --vgaBlue(1) 	<= tilePixel(0);
  -----------------------------------------------------------------------------


end Behavioral;
