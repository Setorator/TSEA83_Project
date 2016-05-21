library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity LED is
	port ( 
		clk,rst 				: in  std_logic;
		
		-- Which segments to be lit (active low)
      seg 					: out  std_logic_vector(7 downto 0);
      
      -- Which display to be lit ("1011" => second display from the left is lit)
      an 					: out  std_logic_vector(3 downto 0);
      
      -- Value to be displayed
      value 				: in  unsigned(15 downto 0)
      );
      
end LED;

architecture Behavioral of LED is

	
	signal segments 			: 	std_logic_vector(6 downto 0);						-- Which segments to be lit/unlit 
	signal refresh_counter 	: 	unsigned(16 downto 0) := (others => '0');		-- Counts to 100 000 thus giving a refresh rate at 1kHz
	signal display_num		:	std_logic_vector(1 downto 0) := "00"; 			-- Which number to be displayed (single, ten, hundred or thousand)
	signal figure				: 	unsigned(3 downto 0) := "0000";					-- The figure to be displayed
	
   signal dp	 				: 	std_logic := '1';										-- Decimal point always unlit
   
begin
	
	
	-- Updates refresh_counter. When 100 000 is reached we switch number to be display (updates display_num)
	-- (100 000 000/100 000)Hz = 1kHz => update frequency of 1 ms.
	update_display : process(clk)
	begin
		if rising_edge(clk) then
		   if rst = '1' then
   			refresh_counter <= (others => '0');
   			display_num <= "00";
   		elsif refresh_counter = 100000 then
   			refresh_counter <= (others => '0');
   			display_num <= display_num + 1;
			else
		   	refresh_counter <= refresh_counter + 1;
		   end if;
		end if;
	end process;
			
	-- Sets the right output for the 7-segment display
  	seg <= (segments & dp);
     
     
     -- Selects the corresponding figure to be display
	with display_num select
		figure <= 	value(15 downto 12) when "00",
						value(11 downto 8) when "01",	
          			value(7 downto 4) when "10",
          			value(3 downto 0) when others;
          			
          			
	-- Displays the corresponding figure on the corresponding display
   display_selection : process(clk) begin
  		if rising_edge(clk) then 
		   
		   -- Convert the figure to be displayed into correct "segments-value"
			case figure is
		      when "0000" => segments <= "0000001";		-- 0
		      when "0001" => segments <= "1001111";		-- 1
		      when "0010" => segments <= "0010010";		-- 2
		      when "0011" => segments <= "0000110";		-- 3
		      when "0100" => segments <= "1001100";		-- 4
		      when "0101" => segments <= "0100100";		-- 5
		      when "0110" => segments <= "0100000";		-- 6
		      when "0111" => segments <= "0001111";		-- 7
		      when "1000" => segments <= "0000000";		-- 8
		      when "1001" => segments <= "0000100";		-- 9
		      when others => segments <= "0110000";		-- E		if error occurs
      	end case;
      
      	-- Choose which display to show the figure on.
		   case display_num is
		      when "00" => an <= "0111";			-- Thousand
		      when "01" => an <= "1011";			-- Hundred
		      when "10" => an <= "1101";			-- Ten
		      when others => an <= "1110";		-- One
      	end case;
    	end if;
   end process;
	
end Behavioral;

