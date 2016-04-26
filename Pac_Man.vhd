-------------------------------------------------------------------------------
-- Top module for our project
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_1164.ALL;                     -- Basic IEEE library
use IEEE.NUMERIC_STD.ALL;                        -- IEEE library for the unsigned type
                                                 -- and various arithmetic operations

                                                 

-- entity
entity Pac_Man is
  
  port (
    clk            : in std_logic;                         	-- System clock
    reset          : in std_logic;                         	-- Reset button
    Hsync			 : out std_logic;								 	-- H-sync for monitor
    Vsync			 : out std_logic;									-- V-sync for monitor
    vgaRed			 : out std_logic_vector(2 downto 0);
    vgaGreen		 : out std_logic_vector(2 downto 0);
    vgaBlue			 : out std_logic_vector(2 downto 1)
         );
    
end Pac_Man;

-- architecture
architecture Behavioral of Pac_Man is


	component CPU
		port (
			clk						  : in std_logic;								-- System clock
			rst						  : in std_logic;								-- Reset button
			intr						  : in std_logic;								-- Interupt signal
			intr2						  : in std_logic;
			intr_code				  : in unsigned(3 downto 0);
			joystick_poss			  : in unsigned(1 downto 0);
			output1					  : out unsigned(18 downto 0);
			output2 					  : out unsigned(18 downto 0);
			output3					  : out unsigned(18 downto 0);
			output4					  : out unsigned(18 downto 0)
		);
	end component;
	

	component PIX_GEN
		port (
			clk                    : in std_logic;                      	-- System clock
			rst                    : in std_logic;                      	-- reset button
			tile_type				  : in std_logic_vector(1 downto 0);		-- Data to be read from MEM
	 		addr						  : out unsigned(10 downto 0);				-- Adress to the tile in MEM
			Hsync                  : out std_logic;                     	-- horizontal sync
			Vsync                  : out std_logic;                     	-- vertical sync
			vgaRed                 : out std_logic_vector(2 downto 0);  	-- VGA red
			vgaGreen               : out std_logic_vector(2 downto 0);  	-- VGA green
			vgaBlue                : out std_logic_vector(2 downto 1);  	-- VGA blue
			colision					  : out std_logic									-- Interupt 
		);
  	end component;
  
  
	component RAM
		port (
			clk							: in std_logic;								-- System clock

			-- port 1
			x1 							: in unsigned(5 downto 0);					-- 64 columns, only 40 is used
			y1 							: in unsigned(4 downto 0);					-- 32 rows, only 30 used
			we 							: in std_logic;								-- Write enable
			data1							: in std_logic_vector(1 downto 0);		-- Data to be written

			-- port 2
			x2 							: in unsigned(5 downto 0);					-- 64 columns, only 40 is used
			y2 							: in unsigned(4 downto 0);					-- 32 rows, only 30 used
			re 							: in std_logic;								-- Read enable
			data2							: out std_logic_vector(1 downto 0)		-- Data to be read		
		);
	end component;
		
  
  signal interupt				: std_logic;											-- Signal between CPU and PIX_GEN
  signal intr2 				: std_logic := '0';
  signal intr_code			: unsigned(3 downto 0)  := (others => '0');
  signal joystick_poss		: unsigned(1 downto 0)  := (others => '0');
  signal output1				: unsigned(18 downto 0)  := (others => '0');
  signal output2 				: unsigned(18 downto 0)  := (others => '0');
  signal output3				: unsigned(18 downto 0)  := (others => '0');
  signal output4				: unsigned(18 downto 0)  := (others => '0');
  
  signal read_enable			: std_logic := '0';
  signal write_enable		: std_logic;
  signal read_addr			: unsigned(10 downto 0);
  signal write_addr			: unsigned(10 downto 0);
  signal read_data			: std_logic_vector(1 downto 0);
  signal write_data			: std_logic_vector(1 downto 0);


begin 

	U0 : CPU port map(clk=>clk, rst=>reset, intr=>interupt, intr2=>intr2, intr_code => intr_code, joystick_poss => joystick_poss,
							 output1 => output1, output2 => output2, output3 => output3, output4 => output4);
							 
	U1 : RAM port map(clk=>clk, we=>write_enable, data1=>write_data, x1=>write_addr(5 downto 0), y1=>write_addr(10 downto 6), 
							re=>read_enable, data2=>read_data, x2=>read_addr(5 downto 0), y2=>read_addr(10 downto 6));

	U2 : PIX_GEN port map(clk=>clk, rst=>reset, tile_type=>read_data,
									Hsync=>Hsync, Vsync=>Vsync, addr=>read_addr,
									vgaRed(2)=>vgaRed(2),
									vgaRed(1)=>vgaRed(1),
									vgaRed(0)=>vgaRed(0),
									vgaGreen(2)=>vgaGreen(2),
									vgaGreen(1)=>vgaGreen(1),
									vgaGreen(0)=>vgaGreen(0),
									vgaBlue(2)=>vgaBlue(2),
									vgaBlue(1)=>vgaBlue(1),
									colision=>interupt);


  
end Behavioral;


