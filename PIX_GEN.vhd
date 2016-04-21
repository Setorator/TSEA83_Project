library IEEE;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations


-- entity
entity PIX_GEN is
	port (
		clk            : in std_logic;                         -- system clock
    	rst            : in std_logic;                         -- reset
	 	tile_type		: in std_logic_vector(1 downto 0);		 -- Type of tile from RAM				
	 	addr				: out unsigned(10 downto 0);				 -- Adress to the tile pixel in RAM
	 	read				: out std_logic;								 -- Read enable for RAM
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

	signal Xpixel        : unsigned(9 downto 0);  				-- Horizontal pixel counter
  	signal Ypixel        : unsigned(9 downto 0);  				-- Vertical pixel counter
  	signal blank			: std_logic;		 						-- blanking signal
  	
  	signal tmpX, tmpY		: unsigned(4 downto 0);					-- Used for tileX and tileY
  	signal tileX			: unsigned(5 downto 0);					-- X-coordinate of the tile
  	signal tileY			: unsigned(4 downto 0);					-- Y-coordinate of the tile
  
  	signal ClkDiv			: unsigned(1 downto 0);					-- Clock divisor, to generate
                                                 				-- 25 MHz clock
  	signal Clk25			: std_logic;		 						-- One pulse width 25 MHz sign
  	
	signal tileData     	: std_logic_vector(7 downto 0);		-- Tile pixel data
	signal tileAddr		: unsigned(10 downto 0);				-- Tile address							-- NOT NEEDED???
	
	signal TilePixel		: std_logic_vector(7 downto 0);		-- Color of chosen tile pixel
	signal PacPixel		: std_logic_vector(7 downto 0);		-- Color of chosen Pac_Man pixel
	signal GhostPixel		: std_logic_vector(7 downto 0);		-- Color of chosen Ghost pixel
	
  
  	-- Tile memory type
  	type tile_t is array (0 to 2047) of std_logic_vector(7 downto 0);  
  	type sprite is array (0 to 255) of std_logic_vector(7 downto 0);
  
	-- Tile memory
  	signal tileMem : tile_t := 
		( x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  -- Floor (Start adress 0)
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
		  
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  -- Food (Start adress 256)
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
		  
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  -- Wall (Start adress 512)
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",  
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"02",x"02",x"02",x"02",x"02",x"02",x"02", x"02",x"02",x"02",x"02",x"02",x"02",x"02",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  others => (others => '1'));
		  
		  
	signal Pac_Man : sprite :=
		( x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  -- Pac_Man (Start adress 0)
		  x"00",x"00",x"00",x"00",x"00",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"00",x"00",x"00",
		  x"00",x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00",x"00",
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00",
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00",
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
		  
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00",
		  x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00",
		  x"00",x"00",x"8C",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"8C",x"00",x"00",
		  x"00",x"00",x"00",x"8C",x"8C",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"8C",x"8C",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"8C",x"8C",x"8C", x"8C",x"8C",x"8C",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");
		  
	signal Ghost : sprite :=
		( x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",  -- Ghost (Start adress 0)
		  x"00",x"00",x"00",x"00",x"00",x"70",x"70",x"70", x"70",x"70",x"70",x"00",x"00",x"00",x"00",x"00",
		  x"00",x"00",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"00",x"00",
		  x"00",x"70",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"00",x"00",x"00",x"70",x"70", x"70",x"70",x"00",x"00",x"00",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"00",x"00",x"00",x"70",x"70", x"70",x"70",x"00",x"00",x"00",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"00",x"00",x"00",x"70",x"70", x"70",x"70",x"00",x"00",x"00",x"70",x"70",x"00",
		  
		  x"00",x"70",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"70",x"70",x"70",x"70",x"70", x"70",x"70",x"70",x"70",x"70",x"70",x"70",x"00",
		  x"00",x"70",x"70",x"00",x"70",x"70",x"70",x"00", x"00",x"70",x"70",x"70",x"00",x"70",x"70",x"00", 
		  x"00",x"70",x"00",x"00",x"00",x"70",x"00",x"00", x"00",x"00",x"70",x"00",x"00",x"00",x"70",x"00", 
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00", x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"); 
		  

begin

------------------------------------------------------------------------
---------------------VGA_MOTOR------------------------------------------
------------------------------------------------------------------------

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
  
  
  
-------------------------------------------------------------------------
----------------------------------PIXEL_GEN------------------------------
-------------------------------------------------------------------------


	big_pixel_xcounter : process(clk)
	begin
		if (rst = '1' or Xpixel > 639 or tmpX = 15) then
			tmpX <= (others => '0');
		else
			tmpX <= tmpX + 1;
		end if;
	end process;
	
	big_pixel_xcoord : process(clk)
	begin
		if rst = '1' or tileX > 39 then
			tileX <= (others => '0');
		else
			tileX <= tileX +1;
		end if;
	end process;
	
	big_pixel_ycounter : process(clk)
	begin
		if (rst = '1' or Ypixel > 479 or tmpY = 15) then
			tmpY <= (others => '0');
		else
			tmpY <= tmpY + 1;
		end if;
	end process;
	
	big_pixel_ycoord : process(clk)
	begin
		if rst = '1' or tileY > 29 then
			tileY <= (others => '0');
		else
			tileY <= tileY +1;
		end if;
	end process;
	
  
  addr <= tileY & tileX;
						

	get_tile_pixel : process(clk)
	begin
		if rising_edge(clk) then
			if tile_type = "00" then
				
			elsif tile_type = "01" then
			
			elsif tile_type = "10" then
			
			end if;
		end if;
	end process;	
  
  
    -- Tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (blank = '0') then
        tileData <= tileMem(to_integer(tileAddr));
      else
        tileData <= (others => '0');
      end if;
    end if;
  end process;
	


  -- Picture memory address composite
 -- addr <= to_unsigned(20, 7) * Ypixel(8 downto 5) + Xpixel(9 downto 5);


  -- VGA generation
  vgaRed(2) 	<= tileData(7);
  vgaRed(1) 	<= tileData(6);
  vgaRed(0) 	<= tileData(5);
  vgaGreen(2)   <= tileData(4);
  vgaGreen(1)   <= tileData(3);
  vgaGreen(0)   <= tileData(2);
  vgaBlue(2) 	<= tileData(1);
  vgaBlue(1) 	<= tileData(0);
  
  

end Behavioral;

