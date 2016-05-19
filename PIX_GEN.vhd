---------------------------------------------
------PIXEL_GENERATOR------------------------
---------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations


-- entity
entity PIX_GEN is
	port (
		clk            : in std_logic;                         -- system clock
    	rst            : in std_logic;                         -- reset
    	
		-- Read
		read_data					: in std_logic_vector(1 downto 0);		-- Data to be read from RAM
		read_enable					: out std_logic;								-- enables RAM read
 		read_addr					: out unsigned(10 downto 0);				-- Adress to the tile in RAM
 		
 		-- Write
 		write_addr					: out unsigned(10 downto 0);				-- Adress to the tile in RAM
		write_enable				: out std_logic;								-- enables RAM write
		write_data					: out std_logic_vector(1 downto 0);		-- Data to be written to RAM    	
    	

	 	Pac_Man_X		: in unsigned(9 downto 0);					 -- Pac_Man X-koord in pixel size		
	 	Pac_Man_Y		: in unsigned(9 downto 0);					 -- Pac_Man Y-koord in pixel size	
		Ghost_X			: in unsigned(9 downto 0);
		Ghost_Y			: in unsigned(9 downto 0);	
		TEST_X			: in unsigned(9 downto 0);
		TEST_Y			: in unsigned(9 downto 0);
		TEST_COLLISION_1	: out std_logic;
		TEST_COLLISION_2	: out std_logic;
    	Hsync          : out std_logic;                        -- horizontal sync
    	Vsync          : out std_logic;                        -- vertical sync
    	vgaRed         : out std_logic_vector(2 downto 0);     -- VGA red
    	vgaGreen       : out std_logic_vector(2 downto 0);     -- VGA green
    	vgaBlue        : out std_logic_vector(2 downto 1);     -- VGA blue
    	colision       : out std_logic;	                	-- Colisions
	colision2      : out std_logic;				-- Ghost colision	
	intr_code      : out unsigned(3 downto 0)
	);
         
end PIX_GEN;


-- architecture
architecture Behavioral of PIX_GEN is


	signal Xpixel        : unsigned(9 downto 0) := (others => '0');  				-- Horizontal pixel counter
  	signal Ypixel        : unsigned(9 downto 0) := (others => '0');  				-- Vertical pixel counter
  	signal blank			: std_logic; 														-- blanking signal
  	
  	signal tmpX, tmpY		: unsigned(3 downto 0) := (others => '0');				-- Index within the tile
  	signal tileX			: unsigned(5 downto 0) := (others => '0');				-- X-coordinate of the tile
  	signal tileY			: unsigned(4 downto 0) := (others => '0');				-- Y-coordinate of the tile
  
  	signal ClkDiv			: unsigned(1 downto 0) := (others => '0');				-- Clock divisor, to generate
                                                 										-- 25 MHz clock
  	signal Clk25			: std_logic := '0';		 										-- One pulse width 25 MHz sign
  	
  	-- För testning av rörelse för Pac-Man
--  	signal SpeedDiv		: unsigned(19 downto 0) := (others => '0');
--  	signal Speed			: std_logic := '0';
  	----------------------
  	
	signal tileData     	: std_logic_vector(7 downto 0) := (others => '0');		-- Tile pixel data
	signal tileAddr		: unsigned(10 downto 0) := (others => '0');				-- Tile address							-- NOT NEEDED???
	
	signal TilePixel		: std_logic_vector(7 downto 0) := (others => '0');		-- Color of chosen tile pixel
	signal PacPixel		: std_logic_vector(7 downto 0) := (others => '0');		-- Color of chosen Pac_Man pixel
	signal GhostPixel		: std_logic_vector(7 downto 0) := (others => '0');		-- Color of chosen Ghost pixel
	signal TestPixel_1	:	std_logic_vector(7 downto 0)	:= (others => '0');
	signal TestPixel_2	:	std_logic_vector(7 downto 0)	:= (others => '0');
	
	--signal Ghost_X		: unsigned(9 downto 0)	:= "0100110000"; -- 0				-- Ghosts X-koord in pixel size
	--signal Ghost_Y		: unsigned(9 downto 0)	:= "0011100000"; -- 0				-- Ghosts Y-koord in pixel si
	
  
  	-- Tile memory type
  	type tile_t is array (0 to 1023) of unsigned(1 downto 0);  
  	type sprite is array (0 to 255) of unsigned(1 downto 0);
  	
  	-- Color Map
  	type color_m is array(0 to 3) of std_logic_vector(7 downto 0);
  	signal color_map : color_m := ( X"00", X"8C", X"02", X"E0"); -- (BLACK, YELLOW, BLUE, RED)
  
	-- Tile memory
  	signal tileMem : tile_t := 
		( "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",  -- Floor (Start adress 0)
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00", -- Food (Start adress 256)
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","01","01", "01","01","00","00","00","00","00","00",
		  "00","00","00","00","00","00","01","01", "01","01","00","00","00","00","00","00",
		  
		  "00","00","00","00","00","00","01","01", "01","01","00","00","00","00","00","00",
		  "00","00","00","00","00","00","01","01", "01","01","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00", 
		  
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00", -- Wall (Start adress 512)
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","10","10","10","10","10","10","10", "10","10","10","10","10","10","10","00",
		  "00","00","00","00","00","00","00","00", "00","00","00","00","00","00","00","00",
		  others => (others => '1'));
		  
		  
	signal Ghost : sprite :=
		( "00","00","00","00","00","00","00","11", "11","00","00","00","00","00","00","00",	-- Ghost (Start adress 0)
		  "00","00","00","00","00","11","11","11", "11","11","11","00","00","00","00","00",
		  "00","00","11","11","11","11","11","11", "11","11","11","11","11","11","00","00",
		  "00","11","11","11","11","11","11","11", "11","11","11","11","11","11","11","00",
		  "00","11","11","11","11","11","11","11", "11","11","11","11","11","11","11","00",
		  "11","11","11","00","00","00","11","11", "11","11","00","00","00","11","11","11",
		  "11","11","11","00","00","00","11","11", "11","11","00","00","00","11","11","11",
		  "11","11","11","00","00","00","11","11", "11","11","00","00","00","11","11","11",
		  
		  "11","11","11","11","11","11","11","11", "11","11","11","11","11","11","11","11",
		  "11","11","11","11","11","11","11","11", "11","11","11","11","11","11","11","11",
		  "11","11","11","11","11","11","11","11", "11","11","11","11","11","11","11","11",
		  "11","11","11","11","11","11","11","11", "11","11","11","11","11","11","11","11",
		  "11","11","11","11","11","11","11","11", "11","11","11","11","11","11","11","11",
		  "11","11","11","00","11","11","11","00", "00","11","11","11","00","11","11","11",
  		  "11","11","00","00","00","11","00","00", "00","00","11","00","00","00","11","11",
		  "11","00","00","00","00","11","00","00", "00","00","11","00","00","00","00","11");
		  
	signal Pac_Man : sprite :=
		( "00","00","00","00","00","00","00","01", "01","00","00","00","00","00","00","00",  -- Pac_Man (Start adress 0)
		  "00","00","00","00","00","01","01","01", "01","01","01","00","00","00","00","00",
		  "00","00","00","01","01","01","01","01", "01","01","01","01","01","00","00","00",
		  "00","00","01","01","01","01","01","01", "01","01","01","01","01","01","00","00",
		  "00","01","01","01","01","01","01","01", "01","01","01","01","01","01","01","00",
		  "00","01","01","01","01","01","01","01", "01","01","01","01","01","01","01","01",
		  "01","01","01","01","01","01","01","01", "01","01","01","00","00","00","00","00",
		  "01","01","01","01","01","01","01","00", "00","00","00","00","00","00","00","00",
		  
		  "01","01","01","01","01","01","01","00", "00","00","00","00","00","00","00","00",
		  "01","01","01","01","01","01","01","01", "01","01","01","00","00","00","00","00",
		  "00","01","01","01","01","01","01","01", "01","01","01","01","01","01","01","01",
		  "00","01","01","01","01","01","01","01", "01","01","01","01","01","01","01","00",
		  "00","00","01","01","01","01","01","01", "01","01","01","01","01","01","00","00",
		  "00","00","00","01","01","01","01","01", "01","01","01","01","01","00","00","00",
		  "00","00","00","00","00","01","01","01", "01","01","01","00","00","00","00","00",
		  "00","00","00","00","00","00","00","01", "01","00","00","00","00","00","00","00");
		  

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
        

  -- Vertical pixel counter
  y_Counter : process(clk)
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
  
  
	-- Sync-signals  
	Hsync <= '0' when (Xpixel > 655 and Xpixel < 752) else '1';
	Vsync <= '0' when (Ypixel > 489 and Ypixel < 492) else '1';
	blank <= '1' when (Xpixel > 639 or Ypixel > 479) else '0';
 
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

	-- Index within tiles
	tmpX <= Xpixel(3 downto 0);	
	tmpY <= Ypixel(3 downto 0);
	
	big_pixel_xcoord : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				tileX <= (others => '0');
			elsif Clk25 = '1' then
				if tileX > 39 or Xpixel > 639 then
					tileX <= (others => '0');
				elsif tmpX = 15 then
					tileX <= tileX + 1;

				end if;
			end if;
		end if;
	end process;
	
	
	big_pixel_ycoord : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				tileY <= (others => '0');
			elsif Clk25 = '1' then
				if tileY > 29 or Ypixel > 479 then
					tileY <= (others => '0');
				elsif tmpY = 15 and Xpixel = 799 then
					tileY <= tileY +1;
				end if;
			end if;
		end if;
	end process;
	
  
  	read_addr <= tileY & tileX;							-- addr(10 downto 6) = tiles y-position
  															-- addr(5 downto 0) = tiles x-position
  		
----------------------------------------------------------------
------------------------------PIXEL_CHOOSER---------------------
----------------------------------------------------------------  															
  										
  										
  	TilePixel <= color_map(to_integer(tileMem((to_integer(tmpY)*16) + to_integer(tmpX))))  when (read_data = "00" and blank = '0') else					-- Floor
  					 color_map(to_integer(tileMem( 256 + (to_integer(tmpY)*16) + to_integer(tmpX))))  when (read_data = "01" and blank = '0') else			-- Food
  					 color_map(to_integer(tileMem( 512 + (to_integer(tmpY)*16) + to_integer(tmpX))))  when (read_data = "11" and blank = '0') else			-- Wall
  					 color_map(0) when (blank = '1') else																												-- For blanking
  					 color_map(3);																																				-- Red (for debugging)
  								 	

  	PacPixel <= color_map(to_integer(Pac_Man(((to_integer(Ypixel) - to_integer(Pac_Man_Y))*16) + (to_integer(Xpixel) - to_integer(Pac_Man_X))))) when (((to_integer(Xpixel) - to_integer(Pac_Man_X)) < 16)
  					and ((to_integer(Xpixel) - to_integer(Pac_Man_X)) > 0) and ((to_integer(Ypixel) - to_integer(Pac_Man_Y)) < 16) and ((to_integer(Ypixel) - to_integer(Pac_Man_Y)) > 0)) else x"00"; 

  	TestPixel_1 <= color_map(to_integer(Pac_Man(((to_integer(Ypixel) - to_integer(TEST_Y))*16) + (to_integer(Xpixel) - to_integer(TEST_X))))) when (((to_integer(Xpixel) - to_integer(TEST_X)) < 16)
  					and ((to_integer(Xpixel) - to_integer(TEST_X)) > 0) and ((to_integer(Ypixel) - to_integer(TEST_Y)) < 16) and ((to_integer(Ypixel) - to_integer(TEST_Y)) > 0)) else x"00"; 		

  	TestPixel_2 <= color_map(to_integer(Pac_Man(((to_integer(Ypixel) - to_integer(TEST_Y + 1))*16) + (to_integer(Xpixel) - to_integer(TEST_X + 1))))) when (((to_integer(Xpixel) - to_integer(TEST_X + 1)) < 16)
  					and ((to_integer(Xpixel) - to_integer(TEST_X + 1)) > 0) and ((to_integer(Ypixel) - to_integer(TEST_Y + 1)) < 16) and ((to_integer(Ypixel) - to_integer(TEST_Y + 1)) > 0)) else x"00";
  					
	GhostPixel <= color_map(to_integer(Ghost(((to_integer(Ypixel) - to_integer(Ghost_Y))*16) + (to_integer(Xpixel) - to_integer(Ghost_X))))) when (((to_integer(Xpixel) - to_integer(Ghost_X)) < 16) 
						and ((to_integer(Xpixel) - to_integer(Ghost_X)) > 0) and ((to_integer(Ypixel) - to_integer(Ghost_Y)) < 16) and ((to_integer(Ypixel) - to_integer(Ghost_Y)) > 0)) else x"00"; 			
  				
  
  
  	tileData <= GhostPixel when (GhostPixel /= "00000000") else
  			TilePixel when (TilePixel /= "00000000") else 
			 PacPixel;

----------------------------------------------------------------
-------------------------COLISION-------------------------------
----------------------------------------------------------------

	TEST_COLLISION_1 <= '1' when ((rst = '0') and (tileData = X"02") and (TestPixel_1 /= X"00")) else '0';
	TEST_COLLISION_2 <= '1' when ((rst = '0') and (tileData = X"02") and (TestPixel_2 /= X"00")) else '0';
  	colision2 <= '1' when ((rst = '0') and (tileData = X"02") and (PacPixel /= X"00")) else '0';
	colision <=  '1' when ((rst = '0') and (tileData = X"E0") and (TilePixel = X"02")) else '0';		
	intr_code <= "0000";			

----------------------------------------------------------------
---------------------------EAT_FOOD-----------------------------
----------------------------------------------------------------

	eat_food : process(clk)
	begin
		if rising_edge(clk) then
			if (TilePixel = X"8C") and (PacPixel /= X"00") then
				write_enable <= '1';
				write_addr <= tileY & tileX;
				write_data <= "00"; 			-- Floor tile
			else
				write_enable <= '0';
			end if;
		end if;
	end process;
				



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

