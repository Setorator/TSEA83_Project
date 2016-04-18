-------------------------------------------------------------------------------
-- Top module for our project
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations

-- entity
entity Pac_Man is
  
  port (
    clock            : in std_logic;                         	-- System clock
    reset            : in std_logic;                         	-- Reset button
    horizontalSync	: out std_logic;								 	-- H-sync for monitor
    verticalSync		: out std_logic;									-- V-sync for monitor
    video         	: out std_logic_vector(7 downto 0)			-- RGB-signal
    																				-- to monitor
         );
    
end Pac_Man;

-- architecture
architecture Behavioral of Pac_Man is


	component CPU
		port (
			clk						  : in std_logic;								-- System clock
			rst						  : in std_logic;								-- Reset button
			intr						  : in std_logic								-- Interupt signal
		);
	end component;
	

	component PIX_GEN
		port (
			clk                    : in std_logic;                      -- System clock
			rst                    : in std_logic;                      -- reset button
			data	 					  : in std_logic_vector(7 downto 0);	-- Data to be read from MEM
	 		addr						  : out std_logic_vector(10 downto 0);			-- Adress to the tile in MEM
			Hsync                  : out std_logic;                     -- horizontal sync
			Vsync                  : out std_logic;                     -- vertical sync
			vgaRed                 : out std_logic_vector(2 downto 0);  -- VGA red
			vgaGreen               : out std_logic_vector(2 downto 0);  -- VGA green
			vgaBlue                : out std_logic_vector(2 downto 1);  -- VGA blue
			colision					  : out std_logic								-- Interupt 
		);
  	end component;
  
  
	component RAM
		port (
			clk							: in std_logic;							-- System clock

			-- port 1
			x1 							: in std_logic_vector(5 downto 0);	-- 64 columns, only 40 is used
			y1 							: in std_logic_vector(4 downto 0);	-- 32 rows, only 30 used
			rw1 							: in std_logic;							-- READ/WRITE
			ce1							: in std_logic;							-- Count enable
			data1_in						: in std_logic_vector(7 downto 0);	-- Data to be written
			data1_out					: out std_logic_vector(7 downto 0);	-- Data to be read
			-- port 2
			x2 							: in std_logic_vector(5 downto 0);	-- 64 columns, only 40 is used
			y2 							: in std_logic_vector(4 downto 0);	-- 32 rows, only 30 used
			rw2 							: in std_logic;							-- READ/WRITE
			ce2							: in std_logic;							-- Count enable
			data2							: out std_logic_vector(7 downto 0)-- Data to be read/written		
		);
	end component;
		
  
  signal interupt				: std_logic;									-- Signal between CPU and PIX_GEN
  
  signal addr_tmp				: std_logic_vector(10 downto 0);
  signal data_tmp				: std_logic_vector(7 downto 0);

begin 

	U0 : CPU port map(clk=>clock, rst=>reset, intr=>interupt);
	U1 : RAM port map(clk=>clock, ce1=>'1', rw1=>'0', data1_in=>"00000000", x1=>"000000", y1=>"00000", 
							ce2=>'0', rw2=>'1', data2=>data_tmp, x2=>addr_tmp(5 downto 0), y2=>addr_tmp(10 downto 6));

	U2 : PIX_GEN port map(clk=>clock, rst=>reset, 
									Hsync=>horizontalSync, Vsync=>verticalSync,
									data=>data_tmp, addr=>addr_tmp,
									vgaRed(2)=>video(7),
									vgaRed(1)=>video(6),
									vgaRed(0)=>video(5),
									vgaGreen(2)=>video(4),
									vgaGreen(1)=>video(3),
									vgaGreen(0)=>video(2),
									vgaBlue(2)=>video(1),
									vgaBlue(1)=>video(0),
									colision=>interupt);


  
end Behavioral;


