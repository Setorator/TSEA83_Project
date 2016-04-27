library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity Pac_Man_tb is
end Pac_Man_tb;

architecture Behavioral of Pac_Man_tb is
  component Pac_Man
    port (
   	  clk             : in std_logic;                         	-- System clock
   	  reset           : in std_logic;                         	-- Reset button
  	     Hsync				: out std_logic;								 	-- H-sync for monitor
    	  Vsync				: out std_logic;									-- V-sync for monitor
   	  vgaRed				: out std_logic_vector(2 downto 0);
    	  vgaGreen		 	: out std_logic_vector(2 downto 0);
    	  vgaBlue			: out std_logic_vector(2 downto 1)
      );
  end component;

  signal clock : std_logic := '0';
  signal reset : std_logic := '0';
  signal hS    : std_logic;
  signal vS    : std_logic;
  signal video : std_logic_vector(7 downto 0);
  
begin

  uut : Pac_Man port map (
    clk   => clock,
    reset   => reset,
    Hsync => hS,
    Vsync => vS,
    vgaRed(2) => video(7),
    vgaRed(1) => video(6),
    vgaRed(0) => video(5),
    vgaGreen(2) => video(4),
    vgaGreen(1) => video(3),
    vgaGreen(0) => video(2),
    vgaBlue(2) => video(1),
    vgaBlue(1) => video(0));

  -- Klocksignal 100 MHz

  clock <= not clock after 5 ns;
  
end Behavioral;
