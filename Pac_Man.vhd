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
		clk     							:	in std_logic;                         	-- System clock
		Hsync								:	out std_logic;				-- H-sync for monitor
		Vsync								:	out std_logic;				-- V-sync for monitor
		vgaRed							: 	out std_logic_vector(2 downto 0);
		vgaGreen							: 	out std_logic_vector(2 downto 0);
		vgaBlue							: 	out std_logic_vector(2 downto 1);
		btnl								: 	in std_logic;
		btnu								: 	in std_logic;
		btnr								: 	in std_logic;
		btnd								: 	in std_logic;
		btns								:  in std_logic  				-- Reset button
	 );
    
end Pac_Man;

-- architecture
architecture Behavioral of Pac_Man is

	component CPU
		port (
			clk							: in std_logic;			-- System clock
			rst							: in std_logic;			-- Reset button
			intr							: in std_logic;			-- Interupt signal
			intr2							: in std_logic;
			intr3							: in std_logic;
			intr_code					: in unsigned(3 downto 0);
			joystick_pos				: in unsigned(1 downto 0);
			output1						: out unsigned(9 downto 0);
			output2 						: out unsigned(9 downto 0);
			output3						: out unsigned(9 downto 0);
			output4						: out unsigned(9 downto 0)
		);
	end component;
	

	component PIX_GEN
		port (
			clk                     : in std_logic;                      		-- System clock
			rst                     : in std_logic;                    		-- reset button
			
			-- Read
			read_data		: in std_logic_vector(1 downto 0);		-- Data to be read from RAM
			read_enable		: out std_logic;				-- enables RAM read
	 		read_addr		: out unsigned(10 downto 0);			-- Adress to the tile in RAM
	 		
	 		-- Write
	 		write_addr		: out unsigned(10 downto 0);			-- Adress to the tile in RAM
			write_enable		: out std_logic;				-- enables RAM write
			write_data		: out std_logic_vector(1 downto 0);		-- Data to be written to RAM
							 		
	 		Pac_Man_X		: in unsigned(9 downto 0);			-- Pac_Mans X-pixel koords
			Pac_Man_Y		: in unsigned(9 downto 0);			-- Pac_Mans Y-pixel koords  
			Ghost_X			: in unsigned(9 downto 0);			-- Ghost X poss
			Ghost_Y			: in unsigned(9 downto 0);			-- Ghost Y poss
			Hsync                   : out std_logic;                     		-- horizontal sync
			Vsync                   : out std_logic;                     		-- vertical sync
			vgaRed                  : out std_logic_vector(2 downto 0);  		-- VGA red
			vgaGreen                : out std_logic_vector(2 downto 0);  		-- VGA green
			vgaBlue                 : out std_logic_vector(2 downto 1);  		-- VGA blue
			intr_code		: out unsigned(3 downto 0);			-- intr_code
			colision		: out std_logic;				-- Interupt 
			colision2		: out std_logic					-- Ghost colision
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
			data2							: out std_logic_vector(1 downto 0);		-- Data to be read		
			
			-- reset
			rst							: in std_logic
		);
	end component;
		
  	
	signal intr					: std_logic;					-- Signal between CPU and PIX_GEN
	signal intr2 					: std_logic;
	signal intr3					: std_logic;
	signal intr_code				: unsigned(3 downto 0)  := (others => '0');
	signal joystick_pos				: unsigned(1 downto 0)	:= "10";
	signal output1					: unsigned(9 downto 0)  := (others => '0');
	signal output2 					: unsigned(9 downto 0) 	:= (others => '0');
	signal output3					: unsigned(9 downto 0) 	:= (others => '0');
	signal output4					: unsigned(9 downto 0)  := (others => '0');

	signal read_enable				: std_logic := '0';
	signal write_enable				: std_logic := '0';
	signal read_addr				: unsigned(10 downto 0);
	signal write_addr				: unsigned(10 downto 0);
	signal read_data				: std_logic_vector(1 downto 0);
	signal write_data				: std_logic_vector(1 downto 0);


begin 


	-- Använd knapparna på Nexys för att styra PacMan

	PACMAN_controller : process(clk)
	begin
		if rising_edge(clk) then	
			if btns = '1' then 
				joystick_pos <= "00";
				intr <= '0';
			elsif btnl = '1' and joystick_pos /= "00" then 
				joystick_pos <= "00";
				intr <= '1';
			elsif btnu = '1' and joystick_pos /= "01" then 
				joystick_pos <= "01";
				intr <= '1';
			elsif btnr = '1' and joystick_pos /= "10" then 
				joystick_pos <= "10";
				intr <= '1';
			elsif btnd = '1' and joystick_pos /= "11" then 
				joystick_pos <= "11";
				intr <= '1';
			else
				intr <= '0';
			end if;
		end if;
	end process;

	U0 : CPU port map(clk=>clk, rst=>btns, intr=>intr, intr2=>intr2, intr3=>intr3, intr_code => intr_code, joystick_pos => joystick_pos,
				output1 => output1, output2 => output2, output3 => output3, output4 => output4);
							 
	U1 : RAM port map(clk=>clk, we=>write_enable, data1=>write_data, x1=>write_addr(5 downto 0), y1=>write_addr(10 downto 6), 
				re=>read_enable, data2=>read_data, x2=>read_addr(5 downto 0), y2=>read_addr(10 downto 6), rst => btns);

	U2 : PIX_GEN port map(clk=>clk, rst=>btns, read_data=>read_data,
				Hsync=>Hsync, Vsync=>Vsync, read_addr=>read_addr, read_enable=>read_enable,
				Pac_Man_X => output1, Pac_Man_Y => output2,
				write_enable=>write_enable, write_addr=>write_addr, write_data=>write_data,
				vgaRed(2)=>vgaRed(2),
				vgaRed(1)=>vgaRed(1),
				vgaRed(0)=>vgaRed(0),
				vgaGreen(2)=>vgaGreen(2),
				vgaGreen(1)=>vgaGreen(1),
				vgaGreen(0)=>vgaGreen(0),
				vgaBlue(2)=>vgaBlue(2),
				vgaBlue(1)=>vgaBlue(1),
				colision=>intr2, 
				colision2=>intr3,
				intr_code => intr_code,
				Ghost_X => output3, Ghost_Y => output4);


  
end Behavioral;


