library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity K4 is
  port (
    clk      : in std_logic;
    rst      : in std_logic;
    intr     : in std_logic;
    Isig     : in std_logic;
    K1sig    : in std_logic;
    K2sig    : in std_logic;
    uPCzero  : in std_logic;
    uPCsig   : in std_logic;
    K4_out   : out std_logic_vector(2 downto 0)
    );
end K4;

architecture behavioral of K4 is

  signal K4_intr : std_logic;
  signal I : std_logic := '0';
  signal K4_input : std_logic_vector(4 downto 0);
  
begin

  -- Sätt skifta läge på I
    
  Vippa_I : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        I <= '0';
      elsif (Isig = '1') then
        I <= not I;
      end if;
    end if;
  end process;
  
  -- Kombinatorik för K4_intr
  
  K4_intr <= (not I) and intr;

  K4_input(0) <= K1sig;
  K4_input(1) <= K2sig;
  K4_input(2) <= uPCsig;
  K4_input(3) <= uPCzero;
  K4_input(4) <= K4_intr;

  with K4_input select
    K4_out <= "010" when "10000",
              "011" when "01000",
              "001" when "00100",
              "000" when "00010",
              "100" when "00001",
              "000" when others;

end behavioral;
