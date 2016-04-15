library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU is
  port (
    clk : in std_logic;
    rst : in std_logic;
    TR  : in unsigned(11 downto 0);
    ALUsig : in unsigned(3 downto 0);
    AR : in unsigned(11 downto 0));
end ALU;

architecture behavioral of ALU is

begin
  ALU_func : process(clk)
  begin 
   if rising_edge(clk) then
      
   end if;
  end process;
end behavioral;

