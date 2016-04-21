library IEEE;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations


-- entity
entity PIX_GEN is
	port (
		clk            : in std_logic;                         -- system clock
    	rst            : in std_logic;                         -- reset
		data	 			: in std_logic_vector(7 downto 0);		 -- Data to be written to MEM
	 	addr				: out unsigned(10 downto 0);				 -- Adress to the tile in MEM
    	Hsync          : out std_logic;                        -- horizontal sync
    	Vsync          : out std_logic;                        -- vertical sync
    	vgaRed         : out std_logic_vector(2 downto 0);     -- VGA red
    	vgaGreen       : out std_logic_vector(2 downto 0);     -- VGA green
    	vgaBlue        : out std_logic_vector(2 downto 1);     -- VGA blue
    	colision       : out std_logic	                		 -- Colisions
	);
         
end PIX_GEN;


-- architecture
architecture Behavioral of PIX_GEN is

	signal Xpixel         : unsigned(9 downto 0);  				-- Horizontal pixel counter
  	signal Ypixel         : unsigned(9 downto 0);  				-- Vertical pixel counter
  	signal blank			 : std_logic;		 						-- blanking signal
  
  	signal ClkDiv			: unsigned(1 downto 0);					-- Clock divisor, to generate
                                                 				-- 25 MHz clock
  	signal Clk25			: std_logic;		 						-- One pulse width 25 MHz sign
  	
	signal tilePixel     : std_logic_vector(7 downto 0);		-- Tile pixel data
	signal tileAddr		: unsigned(10 downto 0);				-- Tile address
  
  
  	-- Tile memory type
  	type ram_t is array (0 to 2047) of std_logic_vector(7 downto 0);  
  
	-- Tile memory
  	signal tileMem : ram_t := 
		( x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  -- Floor
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", 
		  
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  -- Food
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"8C",x"8C", x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"8C",x"8C", x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"8C",x"8C", x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",x"00",  
		  x"00",x"00",x"00",x"00",x"00",x"00",x"8C",x"8C", x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", 
		  
  		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",  	-- Wall
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",  
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02",
		  x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"02", 
		  others => (others => '1'));
		  
		  
		  

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
 
		    -- Clock divisor
  -- divide system clock (100 MHz) by 4
  Clk_div : process(clk)
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
  
  
  
    -- Tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (blank = '0') then
        tilePixel <= tileMem(to_integer(tileAddr));
      else
        tilePixel <= (others => '0');
      end if;
    end if;
  end process;
	


  -- Tile memory address composite
  tileAddr <= unsigned(data(4 downto 0)) & Ypixel(4 downto 2) & Xpixel(4 downto 2);


  -- Picture memory address composite
  addr <= to_unsigned(20, 7) * Ypixel(8 downto 5) + Xpixel(9 downto 5);


  -- VGA generation
  vgaRed(2) 	<= tilePixel(7);
  vgaRed(1) 	<= tilePixel(6);
  vgaRed(0) 	<= tilePixel(5);
  vgaGreen(2)   <= tilePixel(4);
  vgaGreen(1)   <= tilePixel(3);
  vgaGreen(0)   <= tilePixel(2);
  vgaBlue(2) 	<= tilePixel(1);
  vgaBlue(1) 	<= tilePixel(0);
  
  

end Behavioral;
