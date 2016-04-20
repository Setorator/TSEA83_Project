library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity CPU_tb is
end CPU_tb;

architecture Behavioral of CPU_tb is
  component CPU
    port (
      clk : in STD_LOGIC;
      rst : in STD_LOGIC;
      intr : in STD_LOGIC;
      intr2 : in STD_LOGIC
      );
  end component;

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';
  signal intr : std_logic := '0';
  signal intr2 : std_logic := '0';
  
begin

  uut : CPU port map (
    clk   => clk,
    rst   => rst,
    intr  => intr,
    intr2 => intr2);

  -- Klocksignal 100 MHz

  clk <= not clk after 5 ns;
  
end Behavioral;
