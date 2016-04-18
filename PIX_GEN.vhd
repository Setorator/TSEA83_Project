library IEEE;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations


-- entity
entity PIX_GEN is
  port (
    clk            : in std_logic;                         -- system clock
    clk25          : in std_logic;                         -- 25 MHz

    rst            : in std_logic;                         -- reset
         
    Hsync          : out std_logic;                        -- horizontal sync
    Vsync          : out std_logic;                        -- vertical sync
    vgaRed         : out std_logic_vector(2 downto 0);     -- VGA red
    vgaGreen       : out std_logic_vector(2 downto 0);     -- VGA green
    vgaBlue        : out std_logic_vector(2 downto 1);     -- VGA blue
    colision       : out std_logic;                		  -- Colisions
         );
         
end PIX_GEN;


-- architecture
architecture Behavioral of PIX_GEN is

  signal Xpixel         : unsigned(9 downto 0);  -- Horizontal pixel counter
  signal Ypixel         : unsigned(9 downto 0);  -- Vertical pixel counter
  signal blank		: std_logic;		 -- blanking signal

begin

  -- Horizontal pixel counter
  X_Counter : process(clk)
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

  H_Sync : process(clk)
  begin
  	if rising_edge(clk) then
    if Xpixel > 655 and Xpixel < 752 then   -- During 96 cycles we should
                                            -- refresh the display. Check the
                                            -- bottom of lab4-PM
      Hsync <= '0';
    else
      Hsync <= '1';
    end if;
   end if;
  end process;

  
  -- Vertical pixel counter
  Y_Counter : process(clk)
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

  V_sync : process(clk)
  begin
  	if rising_edge(clk) then
    if Ypixel > 489 and Ypixel < 492 then
      Vsync <= '0';
    else
      Vsync <= '1';
    end if;
   end if;
  end process;

  
  -- Video blanking signal

  Blank_Signal : process(clk)
  begin
  	if rising_edge(clk) then
    if Xpixel > 639 or Ypixel > 479 then
      blank <= '1';
    else
      blank <= '0';
    end if;
   end if;
  end process;


end Behavioral;
