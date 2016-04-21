-----------------------------------------
------------BLOCK_RAM--------------------
-----------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity RAM is
	port (
		clk			: in std_logic;					-- Clock pulse
<<<<<<< HEAD
		rst			: in std_logic;					-- Reset button
=======
>>>>>>> f6b619fd576c41b8bb38342cc4baa1f655dd47b7
		
		-- port 1
		x1 			: in std_logic_vector(5 downto 0);		-- 64 columns, only 40 is used
		y1 			: in std_logic_vector(4 downto 0);		-- 32 rows, only 30 used
		rw1 			: in std_logic;								-- READ/WRITE
		ce1			: in std_logic;								-- Count enable
<<<<<<< HEAD
		data1			: inout std_logic_vector(7 downto 0);	-- Data to be read/written
=======
		data1_in		: in std_logic_vector(7 downto 0);		-- Data to be read/written
		data1_out	: out std_logic_vector(7 downto 0);		-- Data to be read/written
>>>>>>> f6b619fd576c41b8bb38342cc4baa1f655dd47b7
		-- port 2
		x2 			: in std_logic_vector(5 downto 0);		-- 64 columns, only 40 is used
		y2 			: in std_logic_vector(4 downto 0);		-- 32 rows, only 30 used
		rw2 			: in std_logic;								-- READ/WRITE
		ce2			: in std_logic;								-- Count enable
<<<<<<< HEAD
		data2			: inout std_logic_vector(7 downto 0)	-- Data to be read/written
=======
		data2			: out std_logic_vector(7 downto 0)	-- Data to be written
>>>>>>> f6b619fd576c41b8bb38342cc4baa1f655dd47b7
	);
end RAM;

architecture Behavioral of RAM is

	-- Declaration of a two-port RAM
	-- with 2048 adresses and 8 bits width
	-- (We only uses 40*30 = 1200 adresses,
	-- each containing a 8-bit colour.)
	type ram_t is array(0 to 2047) of 
		std_logic_vector(7 downto 0);
	
	-- Set all bits to zero
	signal ram : ram_t := (others => (others => '0'));
	
	begin
	
	
	process(clk)
	begin
		if rising_edge(clk) then
		
<<<<<<< HEAD
		-- Synched read/write port 1
		if (ce1 = '0') then
			if (rw1 = '0') then
				ram(40*conv_integer(y1)+
					conv_integer(x1)) <= data1;
			else
				data1 <= ram(40*conv_integer(y1)+
							conv_integer(x1));
			end if;
		end if;
		
		-- synched read from port 2
		if (ce2 = '0') then
			if (rw2 = '1') then 
				data2 <= ram(40*conv_integer(y2)+
								conv_integer(x2));
			end if;
		end if;
		
	end if;
=======
			-- Synched read/write port 1
			if (ce1 = '0') then
				if (rw1 = '0') then
					ram(40*conv_integer(y1)+
						conv_integer(x1)) <= data1_in;
				else
					data1_out <= ram(40*conv_integer(y1)+
								conv_integer(x1));
				end if;
			end if;
		
			-- synched read from port 2
			if (ce2 = '0') then
				if (rw2 = '1') then 
					data2 <= ram(40*conv_integer(y2)+
									conv_integer(x2));
				end if;
			end if;
		
		end if;
>>>>>>> f6b619fd576c41b8bb38342cc4baa1f655dd47b7
	end process;
	
end Behavioral;
	
	
	
