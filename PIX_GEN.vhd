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
		clk                     : in std_logic;                      		-- System clock
		rst                     : in std_logic;                    			-- reset button
		
		-- Read
		read_data					: in std_logic_vector(1 downto 0);			-- Data to be read from RAM
		read_enable					: out std_logic;									-- enables RAM read
 		read_addr					: out unsigned(10 downto 0);					-- Adress to the tile in RAM
 		
 		-- Write
 		write_addr					: out unsigned(10 downto 0);					-- Adress to the tile in RAM
		write_enable				: out std_logic;									-- enables RAM write
		write_data					: out std_logic_vector(1 downto 0);			-- Data to be written to RAM
						 		
		-- Pac_Man data
 		Pac_Man_X					: in unsigned(9 downto 0);						-- Pac_Mans X-pixel koords
		Pac_Man_Y					: in unsigned(9 downto 0);						-- Pac_Mans Y-pixel koords  
		Pac_Man_direction			: in unsigned(1 downto 0);						-- Direction of Pac_Mans movement 
		
		-- Ghost data
		Ghost_X						: in unsigned(9 downto 0);						-- Ghost X poss
		Ghost_Y						: in unsigned(9 downto 0);						-- Ghost Y poss
		
		-- VGA-signals
		Hsync                   : out std_logic;                     		-- horizontal sync
		Vsync                   : buffer std_logic;                     	-- vertical sync  (is buffer since we read from it when assigning point_pulse its value)
		vgaRed                  : out std_logic_vector(2 downto 0);  		-- VGA red
		vgaGreen                : out std_logic_vector(2 downto 0);  		-- VGA green
		vgaBlue                 : out std_logic_vector(2 downto 1);  		-- VGA blue
		
		-- Interupts
		ghost_wall_colision		: out std_logic;									-- (old colision 2)         Colision between Ghost and Wall 
		pacman_wall_colision		: out std_logic;									-- (old colision)           Colision between PacMan and Wall 
--		pacman_ghost_colision	: out	std_logic;									-- (Totally new)            Colision between Pac_Man and Ghostion
		
		-- LED
		display_value				: out unsigned(15 downto 0);					-- Value to be displayed at the 7-segment display
		
		-- Test coordinates
		TEST_X						: in unsigned(9 downto 0);
		TEST_Y						: in unsigned(9 downto 0);
		TEST_COLLISION				: out std_logic
	);
         
end PIX_GEN;


-- architecture
architecture Behavioral of PIX_GEN is

	-- Pixel counters for VGA
	signal Xpixel        : unsigned(9 downto 0) := (others => '0');  				-- Horizontal pixel counter
  	signal Ypixel        : unsigned(9 downto 0) := (others => '0');  				-- Vertical pixel counter
  	
  	-- Blanking signal for VGA
  	signal blank			: std_logic; 														-- blanking signal
  	
  	-- Tile information
  	signal tmpX, tmpY		: unsigned(3 downto 0) := (others => '0');				-- Index within the tile
  	signal tileX			: unsigned(5 downto 0) := (others => '0');				-- X-coordinate of the tile
  	signal tileY			: unsigned(4 downto 0) := (others => '0');				-- Y-coordinate of the tilna
  	
  	-- Generation of a 25 MHz clock
  	signal clkDiv			: unsigned(1 downto 0) := (others => '0');				-- Clock divisor, to generate 25 MHz clock
  	signal clk25			: std_logic := '0';		 										-- One pulse width 25 MHz sign
  	
  	-- Pixel data of all tiles, sprites and the pixel send to the VGA port (VGApixel)
	signal VGApixel	   : std_logic_vector(7 downto 0) := (others => '0');		-- Choosen pixel to be sent to VGA
	signal tilePixel		: std_logic_vector(7 downto 0) := (others => '0');		-- Chosen tile pixel
	signal pacPixel		: std_logic_vector(7 downto 0) := (others => '0');		-- Chosen Pac_Man pixel
	signal ghostPixel		: std_logic_vector(7 downto 0) := (others => '0');		-- Chosen Ghost pix
	
	-- Figures to be shown at the display
	signal food1			: unsigned(3 downto 0) 	:= "0000";							-- One
	signal food10			: unsigned(3 downto 0) 	:= "0000";							-- Ten
	signal food100			: unsigned(3 downto 0) 	:= "0000";							-- Houndred (We don't need thousand since max score is 368)
	signal add_points		: std_logic := '0';												-- Detects if we are to update the score.
	signal point_pulse	: std_logic := '0';												-- Used as a one-pulse to add points.
	
	signal komb				: std_logic	:= '0';
  
  	-- Tile memory type
  	type tile_t is array (0 to 1023) of unsigned(1 downto 0);  
  	type sprite is array (0 to 255) of unsigned(1 downto 0);
  	
  	signal TestPixel_1	: std_logic_vector(7 downto 0) 	:= (others => '0');
	signal TestPixel_2      : std_logic_vector(7 downto 0)  := (others => '0');
  	
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
		  "00","01","01","01","01","01","01","01", "01","01","01","00","00","00","00","00",
		  "01","01","01","01","01","01","01","00", "00","00","00","00","00","00","00","00",
		  
		  "01","01","01","01","01","01","01","00", "00","00","00","00","00","00","00","00",
		  "00","01","01","01","01","01","01","01", "01","01","01","00","00","00","00","00",
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
  										
  										
  	tilePixel <= color_map(to_integer(tileMem((to_integer(tmpY)*16) + to_integer(tmpX))))  when (read_data = "00" and blank = '0') else						-- Floor
  					 color_map(to_integer(tileMem( 256 + (to_integer(tmpY)*16) + to_integer(tmpX))))  when (read_data = "01" and blank = '0') else			-- Food
  					 color_map(to_integer(tileMem( 512 + (to_integer(tmpY)*16) + to_integer(tmpX))))  when (read_data = "11" and blank = '0') else			-- Wall
  					 color_map(0) when (blank = '1') else																																	-- For blanking
  					 color_map(3);																																									-- Red (for debugging)
  									 	

	
  	pacPixel <= -- Right (original sprite layout)
  					-- Choose pixel based on the top left corner
  					color_map(to_integer(Pac_Man(((to_integer(Ypixel) - to_integer(Pac_Man_Y))*16) + (to_integer(Xpixel) - to_integer(Pac_Man_X))))) 
  					when (((to_integer(Xpixel) - to_integer(Pac_Man_X)) <= 15) and ((to_integer(Xpixel) - to_integer(Pac_Man_X)) >= 0) and 
  							((to_integer(Ypixel) - to_integer(Pac_Man_Y)) <= 15)and ((to_integer(Ypixel) - to_integer(Pac_Man_Y)) >= 0)) and 
  							(Pac_Man_direction = "10")  else
  					
  					
  	
  					-- Left
  					-- Choose pixel based on the bottom right corner
  					color_map(to_integer(Pac_Man(((to_integer(Pac_Man_Y) - to_integer(Ypixel))*16) + (to_integer(Pac_Man_X) - to_integer(Xpixel)) - 1))) 
  					when (((to_integer(Xpixel) - to_integer(Pac_Man_X)) <= 15) and ((to_integer(Xpixel) - to_integer(Pac_Man_X)) >= 0) and 
  							((to_integer(Ypixel) - to_integer(Pac_Man_Y)) <= 15) and ((to_integer(Ypixel) - to_integer(Pac_Man_Y)) >= 0)) and 
  							(Pac_Man_direction = "00") else 
  					
  					-- Up
  					-- Choose pixel based on the top right corner
  					color_map(to_integer(Pac_Man(((to_integer(Pac_Man_X) - to_integer(Xpixel))*16) + (to_integer(Pac_Man_Y) - to_integer(Ypixel)) - 1))) 
  					when (((to_integer(Xpixel) - to_integer(Pac_Man_X)) <= 15) and ((to_integer(Xpixel) - to_integer(Pac_Man_X)) >= 0) and 
  							((to_integer(Ypixel) - to_integer(Pac_Man_Y)) <= 15) and ((to_integer(Ypixel) - to_integer(Pac_Man_Y)) >= 0)) and 
							(Pac_Man_direction = "01") else 
  					
  					-- Down
  					-- Choose pixel based on the bottom left corner
  					color_map(to_integer(Pac_Man(((to_integer(Xpixel) - to_integer(Pac_Man_X))*16) + (to_integer(Ypixel) - to_integer(Pac_Man_Y))))) 
  					when (((to_integer(Xpixel) - to_integer(Pac_Man_X)) <= 15) and ((to_integer(Xpixel) - to_integer(Pac_Man_X)) >= 0) and 
  							((to_integer(Ypixel) - to_integer(Pac_Man_Y)) <= 15) and ((to_integer(Ypixel) - to_integer(Pac_Man_Y)) >= 0)) and 
  							(Pac_Man_direction = "11") else X"00";
  					
  					
  					
	ghostPixel <= 	
						color_map(to_integer(Ghost(((to_integer(Ypixel) - to_integer(Ghost_Y))*16) + (to_integer(Xpixel) - to_integer(Ghost_X))))) 
						when (((to_integer(Xpixel) - to_integer(Ghost_X)) <= 15) and ((to_integer(Xpixel) - to_integer(Ghost_X)) >= 0) and 
						((to_integer(Ypixel) - to_integer(Ghost_Y)) <= 15) and ((to_integer(Ypixel) - to_integer(Ghost_Y)) >= 0)) else X"00";
  
  
  	VGApixel <= 
  					ghostPixel when (ghostPixel /= "00000000") else
  					tilePixel when (tilePixel /= "00000000") else pacPixel;
  					
  					
  					
  	TestPixel_1 <= 
  						color_map(to_integer(Pac_Man(((to_integer(Ypixel) - to_integer(TEST_Y - 1))*16) + (to_integer(Xpixel) - to_integer(TEST_X - 1))))) 
  						when (((to_integer(Xpixel) - to_integer(TEST_X - 1)) < 16) and ((to_integer(Xpixel) - to_integer(TEST_X - 1)) >= 0) and 
  								((to_integer(Ypixel) - to_integer(TEST_Y - 1)) < 16) and ((to_integer(Ypixel) - to_integer(TEST_Y - 1)) >= 0)) else X"00"; 
  										

  	TestPixel_2 <= 
  						color_map(to_integer(Pac_Man(((to_integer(Ypixel) - to_integer(TEST_Y + 1))*16) + (to_integer(Xpixel) - to_integer(TEST_X + 1))))) 
  						when (((to_integer(Xpixel) - to_integer(TEST_X + 1)) < 16) and ((to_integer(Xpixel) - to_integer(TEST_X + 1)) >= 0) and 
  								((to_integer(Ypixel) - to_integer(TEST_Y + 1)) < 16) and ((to_integer(Ypixel) - to_integer(TEST_Y + 1)) >= 0)) else X"00"; 	

----------------------------------------------------------------
-------------------------COLISION-------------------------------
----------------------------------------------------------------
  	
  	TEST_COLLISION <= '1' when ((rst = '0') and (VGApixel = X"02") and ((TestPixel_1 /= X"00") or (TestPixel_2 /= X"00"))) else '0';
  	
  	-- Colision when Pac_Man collide with the wall				
  	pacman_wall_colision <= '1' when ((rst = '0') and (VGApixel = X"02") and (pacPixel = X"8C")) else '0';
  	
  	-- Colision when Ghost collides woth the wall
	ghost_wall_colision <=  '1' when ((rst = '0') and (VGApixel = X"E0") and (tilePixel = X"02")) else '0';		
	
--	pacman_ghost_colision <= '1' when ((rst = '0') and (VGApixel = X"E0") and (pacPixel = X"8C")) else '0';

----------------------------------------------------------------
---------------------------EAT_FOOD-----------------------------
----------------------------------------------------------------

	eat_food : process(clk)
	begin
		if rising_edge(clk) then
			if ((tilePixel = X"8C") and (pacPixel /= X"00") and (add_points = '0')) then
				add_points <= '1';
				write_enable <= '0';
				write_addr <= tileY & tileX;
				write_data <= "00"; 			-- Floor tile		
			elsif (add_points = '1' and Vsync = '0') then 
				add_points <= '0';
				point_pulse <= '1';
			else
				write_enable <= '1';
				point_pulse <= '0';
			end if;
		end if;
	end process;
	
	
	
	add_point : process(clk)
	begin
		if rising_edge(clk) then
			if point_pulse = '1' then
				if food1 > 8 then							-- Adds score altough not with the correct score.
					if food10 > 8 then					-- Different score depending on which way you eat from.
						if food100 > 8 then				-- Gonna try to write out Pac-Man in the corresponding way and
							food1 <= "0000";				-- see if that fixes the problem.
							food10 <= "0000";
							food100 <= "0000";
						else
							food100 <= food100 + 1;
							food10 <= "0000";
							food1 <= "0000";
						end if;
					else
						food10 <= food10 + 1;
						food1 <= "0000";
					end if; 
				else
					food1 <= food1 + 1;
				end if;	
			end if;
		end if;
	end process;
	
	
	

----------------------------------------------------------------
--------------------------LED-----------------------------------
----------------------------------------------------------------


	display_value(15 downto 12) <= "0000";
	display_value(11 downto 8)	<=	food100;
	display_value(7 downto 4) <= food10;
	display_value(3 downto 0) <= food1;
				
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------



  -- VGA generation
  vgaRed(2) 	<= VGApixel(7);
  vgaRed(1) 	<= VGApixel(6);
  vgaRed(0) 	<= VGApixel(5);
  vgaGreen(2)   <= VGApixel(4);
  vgaGreen(1)   <= VGApixel(3);
  vgaGreen(0)   <= VGApixel(2);
  vgaBlue(2) 	<= VGApixel(1);
  vgaBlue(1) 	<= VGApixel(0);
  

end Behavioral;

