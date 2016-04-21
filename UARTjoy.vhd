library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity uartJoy is
    Port ( clk, rst, fromJoy : in  STD_LOGIC;
	   inter : out STD_LOGIC;
	   toJoy, cs : out STD_LOGIC := 0;
       xpos, ypos : out  STD_LOGIC_VECTOR(15 downto 0)); -- x och y pos används som skiftregister
end uartJoy;


architecture Behavioral of uartJoy is
	signal bit_counter : STD_LOGIC_VECTOR(5 downto 0);
	signal rx1,rx2 : std_logic;         -- vippor på insignalen
    signal sp : std_logic;              -- skiftpuls
	signal stopsend : std_logic := '0'; -- märker när xpos och ypos fått in alla bitar
	signal xory : std_logic := '0';		-- bestämmer vilken av positionerna som ska ha den ingående biten (fromJoy)
	 
    
    
    signal styr_count : STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- Räknaren till styrenheten
    signal clock_counter : STD_LOGIC_VECTOR(9 downto 0) := "0000000000"; -- Räknaren av klockpulser
	-- clk_period kan behöva ändras
    constant clk_period :  time :=  8.68 us;  -- Clock period definitions

begin

  -- *****************************
  -- *  synkroniseringsvippor    *
  -- *****************************
  
  process(clk)
  begin
	if rising_edge(clk)	then
		if rst='1' then
			rx1 <= '0';
			rx2 <= '0';
		else 
			rx1 <= fromJoy;
			rx2 <= rx1;
		end if;
	end if;
  end process;

  -- *****************************
  -- *       styrenhet           *
  -- *****************************

  -- clock_counter värdet (434) kan behöva ändras

  process(clk)
  begin
	if rising_edge(clk) then
		if rst='1' then
			styr_count <= "0000";
			sp <= '0';
		elsif styr_count = 15 and clock_counter = 434 then
			styr_count <= "0000";
			sp <= '1';
		elsif styr_count = 0 and rx2 = '0' and clock_counter = 434 then
			styr_count <= "0001";
			sp <= '1';
		elsif styr_count /= 0 and clock_counter = 434 then
			styr_count <= styr_count + 1;
			sp <= '1';
		else	
			sp <= '0';
		end if;
	end if;
  end process;

  
  -- *****************************
  -- * 16 bit skiftregister      *
  -- *****************************
   
  process(clk)
  begin
	if rising_edge(clk) then
		if rst='1' then
			xpos <= "0000000000000000";
			ypos <= "0000000000000000";
		elsif sp = '1' and xory = '0' and stopsend = '0' then
			xpos <= rx2 & xpos(15 downto 1);
		elsif sp = '1' and xory = '1' and stopsend = '0' then
			ypos <= rx2 & ypos(15 downto 1);
		end if;
	end if;
  end process;

  -- *****************************
  -- * Klockan för xpos och ypos      *
  -- *****************************
   
  process(clk)
  begin
	if rising_edge(clk) then
		if rst='1' then
			bit_counter <= "000000";
		elsif bit_counter = "101000";
			inter <= '0';
			bit_counter <= "000000";
		else
			bit_counter <= bit_counter + '1';
		end if;
	end if;
  end process;

  -- *****************************
  -- * Kontroll för xpos och ypos      *
  -- *****************************
   
  process(clk)
  begin
	if rising_edge(clk) then
		if rst='1' then
			stopsend <= '0';
		elsif bit_counter = "000000" then
			stopsend <= '0';
			xory <= '0';
		elsif bit_counter = "010001" then
			stopsend <= '0';
			xory <= '1';
		elsif bit_counter = "100001" then
			inter <= '1';
			stopsend <= '1';
		end if;
	end if;
  end process;


