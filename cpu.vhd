-- Detta är en CPU av Olle roos typ med avbrott
-- Alla register förrutom DR och IR är 12 bitar breda, DR och IR är 19
-- Program minnet är 19 bitar brett
-- Bussen är 19 bitar brett
-- Mikrominnet är 33 bitar brett
-- Signaler som kan användas fast inte går mellan buss och
-- register nås genom att endast ange FB


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
  signal ALUsig   : unsigned(3 downto 0);
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

  -- K4 out

  signal K4_out : std_logic_vector(2 downto 0);
  
  -- K1 out

  signal K1_out : unsigned(7 downto 0);

  -- K2 out

  signal K2_out : unsigned(7 downto 0);
  
  -- uPCnext = uPC + 1 

  signal uPCnext : unsigned(7 downto 0);
  
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
  signal DATA_BUS : unsigned(18 downto 0);   -- Bussen 2 byte

  -- N flagga
  
  signal N : std_logic := '0';

  -- Z flagga

  signal Z : std_logic := '0';

  component K1
    port(
      K1_in : in unsigned(4 downto 0);
      K1_out : out unsigned(7 downto 0));
  end component;

  component K2
    port(
      K2_in : in unsigned(1 downto 0);
      K2_out : out unsigned(7 downto 0)
      );
  end component;
  
  component K4
    port (
      clk : in std_logic;
      rst : in std_logic;
      intr  : in std_logic;
      Isig     : in std_logic;
      K1sig    : in std_logic;
      K2sig    : in std_logic;
      uPCzero  : in std_logic;
      uPCsig   : in std_logic;
      K4_out   : out std_logic_vector(2 downto 0));
  end component;
  
begin 
    --  Sätt Z och N flaggorna

    N <= SP(0);
    Z <= SP(1);
  
    -- Kombinatorik för avläsning uM
    
    uAddr <= uM(7 downto 0);
    SPsig <= uM(9 downto 8);
    RW <= uM(10);
    SEQ <= uM(14 downto 11);
    Isig <= uM(15);
    PCsig <= uM(16);
    FB <= uM(22 downto 17);
    TB <= uM(28 downto 23);
    ALUsig <= uM(32 downto 29);

    -- Installera alla till och från signaler

    DATA_BUS <= IR when (TB = 8) else
                DR when (TB = 6) else
                PC when (TB = 18) else
                XR when (TB = 20) else
                SP when (TB = 24) else
                TR when (TB = 26) else
                SR when (TB = 36) else
                AR when (TB = 37) else 
                (others => '0') when (rst = '1') else
                (others => '0');

    ADR_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          ADR <= (others => '0');
        elsif FB = 1 then
          ADR <= DATA_BUS(11 downto 0);
        end if;
      end if;
    end process;

    XR_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          XR <= (others => '0');
        elsif FB = 19 then
          XR <= DATA_BUS(11 downto 0);
        end if;
      end if;
    end process;

   -- SPsig == 1 => SP++, SPsig == 2 => SP--, SPsig == 3 => SPsig = 0
    
    SP_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          SP <= (others => '0');
        elsif FB = 21 then
          SP <= DATA_BUS(11 downto 0);
        elsif SPsig = 1 then
          SP <= SP + 1;
        elsif SPsig = 2 then
          SP <= SP - 1;
        elsif SPsig = 3 then
          SP <= (others => '0');
        end if;
      end if;
    end process;

    TR_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          TR <= (others => '0');
        elsif FB = 25 then
          TR <= DATA_BUS(11 downto 0);
        elsif FB = 32 then
          AR <= TR;
        end if;
      end if;
    end process;


    SR_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          SR <= (others => '0');
        elsif FB = 35 then
          SR <= DATA_BUS(11 downto 0);
        elsif FB = 34 then
          SR <= AR;
        end if;
      end if;
    end process;

    HR_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          HR <= (others => '0');
        elsif FB = 38 then
          HR <= AR;
        end if;
      end if;
    end process;

    DR_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          DR <= (others => '0');
        elsif FB = 6 then
          DR <= DATA_BUS(18 downto 0);
        elsif (RW = '0') and (FB = 2) then
          DR <= p_mem(to_integer(ADR));
        elsif (RW = '1') and (FB = 2) then
          p_mem(to_integer(ADR)) <= DR;
        end if;
      end if;
    end process;

    -- Mappning till ingångar för K4
    
    U0 : K4 port map (
      clk      => clk,
      rst      => rst,
      Isig     => Isig,
      intr     => intr,
      K1sig    => K1sig,
      K2sig    => K2sig,
      uPCzero  => uPCzero,
      uPCsig   => uPCsig,
      K4_out   => K4_out
      );

    -- Koppla in K1 och K2 till muxen, K4_out väljer
    -- Address till avbrotts rutin  = 60
    
    with K4_out select
      uPC <= uPCnext    when "000",
             K1_out     when "001",
             "00000000" when "010",
             K2_out     when "011",
             "00111100" when "100",
             uPCnext    when others;

    -- Sätt mikrosignalen
    
    uM <= u_mem(to_integer(uPC));

    -- Installera K1

    U1 : K1 port map (
      K1_in => IR(18 downto 14),
      K1_out => K1_out
      );

    -- Installera K2
    
    U2 : K2 port map (
      K2_in => IR(13 downto 12),
      K2_out => K2_out
      );

    -- Installera ALU

    -- ALU Kommer att fungera lite olikt den originella Olle roos datorn då vi
    -- inte kommer att behöva 27 och 33 som signaler om vi har en LOAD funktion
    -- på ALU:n. För att tillexempel köra en ADD så kör först LOAD på det som
    -- ligger i TR så TR hamnar i AR. Lägg det du vill ADDA i TR och kör ADD så
    -- blir AR <= AR + TR.

    ALU_func : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          AR <= (others => '0');
        elsif ALUsig = 28 then
          AR <= AR + 1;
        elsif ALUsig = 29 then
          AR <= AR - 1;
        elsif ALUsig = 30 then
          AR <= AR + TR;
        elsif ALUsig = 31 then
          AR <= AR - TR;
        elsif ALUsig = 32 then
          AR <= TR;
        end if;
      end if;
    end process;
    
  end Behavioral;
  
