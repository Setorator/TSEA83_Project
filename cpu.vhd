-- Detta är en CPU av Olle roos typ med avbrott
-- Alla register förrutom DR och IR är 12 bitar breda, DR och IR är 19
-- Program minnet är 19 bitar brett
-- Bussen är 19 bitar brett
-- Mikrominnet är 33 bitar brett


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CPU Interface

entity cpu is 
  port (
    clk         :  in std_logic;
    rst         :  in std_logic;
    intr        :  in std_logic
  );
end cpu;

architecture Behavioral of cpu is 

  -- micro memory
  
  type u_mem_t is array(0 to 255) of unsigned(32 downto 0);

  -- uM = ALU_TB_FB_PC_I_SEQ_RW_SP_uAddr
  
  -- Skriv mikrominne nedanför
  constant u_mem_c : u_mem_t := (others => (others => '0'));

  signal u_mem : u_mem_t := u_mem_c;

  signal uM    : unsigned(32 downto 0);        -- micro memory output
  signal uPC   : unsigned(7 downto 0);         -- micro program counter

  -- Signaler i uM
  signal uAddr : unsigned(7 downto 0);         -- micro Adress
  signal TB    : unsigned(5 downto 0);         -- to bus field
  signal FB    : unsigned(5 downto 0);         -- from bus field
  signal ALU   : unsigned(3 downto 0);
  signal Isig  : std_logic;                    -- block interrupts
  signal RW    : std_logic;                    -- Read/write
  signal SEQ   : unsigned(3 downto 0);
  signal SPsig : unsigned(1 downto 0);         -- Manipulera stackpekaren
  signal PCsig : std_logic;                    -- PC++

  -- Nollställ uPC

  signal uPCzero : std_logic;

  -- uPC++
  signal uPCsig : std_logic;

  -- Läs K1

  signal K1sig : std_logic;

  -- Läs K2

  signal K2sig : std_logic;

  -- I-vippan
  
  signal I : std_logic;

  -- K4 avbrott

  signal K4_intr : std_logic;

  -- K4 input

  signal K4_input : std_logic_vector(4 downto 0);
  
  -- K4 output

  signal K4_output : std_logic_vector(4 downto 0);
  
  -- program memory
  
  type p_mem_t is array(0 to 4095) of unsigned(18 downto 0);

  -- Skriv program minne nedanför
  
  constant p_mem_c : p_mem_t :=  (others => (others => '0'));           

  signal p_mem : p_mem_t := p_mem_c;         -- Sätt program minne

  signal DR     : unsigned(18 downto 0);     -- Dataregister
  signal ADR    : unsigned(11 downto 0);     -- Address register
  signal PC     : unsigned(11 downto 0);     -- Program räknaren
  signal IR     : unsigned(18 downto 0);     -- Instruktion register
  signal XR     : unsigned(11 downto 0);     -- XR
  signal SP     : unsigned(11 downto 0);     -- Stack pekare
  signal TR     : unsigned(11 downto 0);     -- Temporära register
  signal AR     : unsigned(11 downto 0);     -- Ackumulator register
  signal SR     : unsigned(11 downto 0);     -- Status register
  signal HR     : unsigned(11 downto 0);     -- Hjälp register
  signal DATA_BUSS : unsigned(18 downto 0);   -- Bussen 2 byte
  
  begin
    -- Sätt mikrosignalen
    
    uM <= u_mem(to_integer(uPC));
    
    -- Kombinatorik för avläsning uM
    
    uAddr <= uM(7 downto 0);
    SPsig <= uM(9 downto 8);
    RW <= uM(10);
    SEQ <= uM(14 downto 11);
    Isig <= uM(15);
    PCsig <= uM(16);
    FB <= uM(22 downto 17);
    TB <= uM(28 downto 23);
    ALU <= uM(32 downto 29);

    -- Sätt skifta läge på I
    
    Vippa_I : process(clk)
    begin
      if rising_edge(clk) then
        if (rst = '1') then 
          I <= '0';
        elsif (Isig = '1') then
          I <= not I;
        end if;
      end if;
    end process;
      
    -- Kombinatorik för K4_intr

    K4_intr <= (not I) and intr;

    -- Kombinatorik för K4

    K4_input(0) <= K1sig;
    K4_input(1) <= K2sig;
    K4_input(2) <= uPCzero;
    K4_input(3) <= uPCsig;
    K4_input(4) <= K4_intr;

    with K4_input select
      K4_output <= "010" when "10000",
                   "011" when "01000",
                   "001" when "00100",
                   "000" when "00010",
                   "100" when "00001",
                   "000" when others;

    
  end Behavioral;
  
