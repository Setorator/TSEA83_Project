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
  
  -- K1 out

  signal K1_out : unsigned(7 downto 0);

  -- K2 out

  signal K2_out : unsigned(7 downto 0);
  
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
  signal DATA_BUS : unsigned(18 downto 0);   -- Bussen 2 byte

  -- Flaggorna
  
  signal N : std_logic := '0';
  signal Z : std_logic := '0';
  signal O : std_logic := '0';
  signal C : std_logic := '0';
  signal L : std_logic := '0';

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
begin 
  
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

   -- SPsig == 1 => SP++, SPsig == 2 => SP--, SPsig == 3 => SP = 0
    
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
	
	uM_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then uM <= (others => '0');
			elsif intr = '1' then uPC <= "00111100"; --60
			elsif SEQ = 0 then uPC <= uPC + 1;
			elsif SEQ = 1 then uPC <= K1_out;
			elsif SEQ = 2 then uPC <= K2_out;
			elsif SEQ = 3 then uPC <= (others => '0');
			elsif SEQ = 4 then 
				if Z = '0' then 
					uPC <= uAddr;
				else     
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 5 then uPC <= uAddr;
			elsif SEQ = 6 then
				if Z = '1' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 7 then
				if N = '1' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 8 then
				if C = '1' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 9 then
				if O = '1' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 10 then
				if L = '1' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 11 then
				if C = '0' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 12 then
				if O = '0' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 13 then
				uPC <= (others => '0'); -- HALT
			end if; 
		end if;
	end process;

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
    -- inte kommer att behöva 27 och 33. ALUsig är 4 bitar så det finns 16 möjliga operationer att definera

    ALU_func : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' 	 then AR <= (others => '0');
		elsif FB = 34    then AR <= DATA_BUS(11 downto 0);
        elsif ALUsig = 1 then AR <= AR + 1;
        elsif ALUsig = 2 then AR <= AR - 1;
        elsif ALUsig = 3 then AR <= AR + TR;
        elsif ALUsig = 4 then AR <= AR - TR;
        end if;
      end if;
    end process;
    
  end Behavioral;
  
