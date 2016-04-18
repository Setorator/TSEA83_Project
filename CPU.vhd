-- Detta är en CPU av Olle roos typ med avbrott
-- Alla register förrutom DR och IR är 12 bitar breda, DR och IR är 19
-- Program minnet är 19 bitar brett
-- Bussen är 19 bitar brett
-- Mikrominnet är 28 bitar brett
-- Signaler som kan användas fast inte går mellan buss och
-- register nås genom att endast ange FB
-- TR, SR och HR är register som är bortagna då vi inte kommer att behöva dom


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
  
  type u_mem_t is array(0 to 255) of unsigned(29 downto 0);
  
  -- Skriv mikrominne här
  constant u_mem_c : u_mem_t := 
		   --      ALU _ TB _ FB _P_I_ SEQ_RW_SP_  uAddr
				(b"0000_0110_0001_0_1_0000_00_00_00000000", -- ADR <= PC				0
				 b"0000_0000_0000_0_0_0000_10_00_00000000", -- DR <= MEM(ADR)			1
				 b"0000_0101_0010_0_0_0000_00_00_00000000", -- IR <= DR					2
				 b"0000_0000_0000_1_0_0010_00_00_00000000", -- PC++, uPC <= K2			3
				 -- M = "00" , Direkt addressering
				 b"0000_0010_0001_0_0_0000_00_00_00000000", -- ADR <= IR				4
				 b"0000_0000_0000_0_0_0001_10_00_00000000", -- DR <= MEM(ADR)			5
				 -- M = "01" , Omedelbar operand
				 b"0000_0110_0001_0_0_0000_00_00_00000000", -- ADR <= PC				6
				 b"0000_0000_0000_1_0_0001_10_00_00000000", -- DR <= MEM(ADR), PC++ 	7
				 -- M = "10" , Indirekt addressering
				 b"0000_0010_0001_0_0_0000_00_00_00000000", -- ADR <= IR				8
				 b"0000_0000_0000_0_0_0000_10_00_00000000", -- DR <= MEM(ADR)			9
				 b"0000_0101_0001_0_0_0000_00_00_00000000", -- ADR <= DR				10
				 b"0000_0000_0000_0_0_0001_10_00_00000000", -- DR <= MEM(ADR)			11
				 -- M = "11" , Indexerad addresering
				 b"0000_0010_0111_0_0_0000_00_00_00000000", -- AR <= IR					12
				 b"0011_0100_0111_0_0_0000_00_00_00000000", -- AR <= AR + XR			13
				 b"0000_0111_0001_0_0_0000_00_00_00000000", -- ADR <= AR				14
				 b"0000_0000_0000_0_0_0001_10_00_00000000", -- DR <= MEM(ADR)			15
				 -- OP = 00000, LDA M,ADDR  , AR <= MEM(ADDR)			
				 b"0000_0101_0111_0_1_0011_00_00_00000000", -- AR <= DR, uPC <= 0		16
				 -- OP = 00001, STXR M,ADDR , MEM(DR) <= XR
				 b"0000_0101_0001_0_0_0000_00_00_00000000", -- ADR <= DR      			17
				 b"0000_0100_0101_0_0_0000_00_00_00000000", -- DR <= XR					18
				 b"0000_0000_0000_0_1_0011_11_00_00000000", -- MEM(ADR) <= XR,uPC <= 0	19
				 -- Avbrottsrutin, Lägg undan alla register i minnet
				 b"0000_0110_0101_0_0_0000_00_00_00000000", -- DR <= PC					20
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--			21
				 b"0000_1000_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= SR 22
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--			23
				 b"0000_0111_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= AR 24
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--			26
				 others => (others => '0'));

  signal u_mem : u_mem_t := u_mem_c;

  signal uM    : unsigned(29 downto 0) := (others => '0');        -- micro memory output
  signal uPC   : unsigned(7 downto 0) := (others => '0');         -- micro program counter

  -- Signaler i uM
  signal uAddr : unsigned(7 downto 0)  := (others => '0');         -- micro Adress
  signal TB    : unsigned(3 downto 0)  := (others => '0');         -- to bus field
  signal FB    : unsigned(3 downto 0) := (others => '0');          -- from bus field
  signal ALUsig   : unsigned(3 downto 0) := (others => '0');
  signal Isig  : std_logic := '0';                   			   -- block interrupts
  signal RW    : unsigned(1 downto 0) := (others => '0');          -- Read/write
  signal SEQ   : unsigned(3 downto 0)  := (others => '0');
  signal SPsig : unsigned(1 downto 0)  := (others => '0');         -- Manipulera stackpekaren
  signal PCsig : std_logic := '0';                    			   -- PC++
  signal I     : std_logic := '0'; 				   				   -- T-vippa
  signal intr_vippa : std_logic := '0';							   -- Vippa som säger om ett avbrott ska ske 
  
  -- K1 out

  signal K1_out : unsigned(7 downto 0) := (others => '0');

  -- K2 out

  signal K2_out : unsigned(7 downto 0) := (others => '0');
  
  -- K2 minne
  
  type K2_mem_t is array(0 to 3) of unsigned(7 downto 0);
  
  constant intr_vector : unsigned(7 downto 0) := "00010100"; -- 20
  
  -- Skriv K2 minne nedanför
  constant K2_mem_c : K2_mem_t :=   ("00000100", --Direkt addressering
									 "00000110", --Omedelbar operand
									 "00001000", --Indirekt addressering
									 "00001100", --Indexerad addressering
									others => (others => '0')); 
  
  signal K2_mem : K2_mem_t := K2_mem_c;
  
  -- K1 minne
  
  type K1_mem_t is array(0 to 31) of unsigned(7 downto 0);
  
  -- Skriv K1 minne nedanför
  constant K1_mem_c : K1_mem_t := 
				("00010000",
				 "00010001",
				others => (others => '0')); 
  
  signal K1_mem : K1_mem_t := K1_mem_c; 
  
  -- program memory
  
  type p_mem_t is array(0 to 4095) of unsigned(18 downto 0);
  
  -- Skriv program minne här 
  constant p_mem_c : p_mem_t :=  
			-- OP_M_ADDR
			(b"00000_11_000000000001",
			 b"00000_00_000000000011",
			 b"00000_00_111100001111",
			others => (others => '0'));    

  signal p_mem : p_mem_t := p_mem_c;

  signal DR       : unsigned(18 downto 0) := (others => '0');     -- Dataregister
  signal ADR      : unsigned(11 downto 0) := (others => '0');     -- Address register
  signal PC       : unsigned(11 downto 0) := (others => '0');     -- Program räknaren
  signal IR       : unsigned(18 downto 0) := (others => '0');     -- Instruktion register
  signal XR       : unsigned(11 downto 0) := "000000000001";      -- XR
  signal SP       : unsigned(11 downto 0) := "111111111111";      -- Stack pekare, startar på $FFF
  signal SR       : unsigned(11 downto 0) := (others => '0');     -- Status register
  signal AR       : unsigned(11 downto 0) := (others => '0');     -- Ackumulator register
  signal DATA_BUS : unsigned(18 downto 0) := (others => '0');     -- Bussen 19 bitar

  -- Flaggorna
  
  signal N : std_logic := '0';
  signal Z : std_logic := '0';
  signal O : std_logic := '0';
  signal C : std_logic := '0';

begin 
  
	-- Installera avbrotts vippan
	
	INTR_vippan : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				intr_vippa <= '0';
			elsif intr = '1' then
				intr_vippa <= '1';
			end if;
		end if;
	end process;
  
    -- Kombinatorik för avläsning uM
    
    uAddr <= uM(7 downto 0);
    SPsig <= uM(9 downto 8);
    RW <= uM(11 downto 10);
    SEQ <= uM(15 downto 12);
    Isig <= uM(16);
    PCsig <= uM(17);
    FB <= uM(21 downto 18);
    TB <= uM(25 downto 22);
    ALUsig <= uM(29 downto 26);

    -- Installera alla signaler till bussen

    DATA_BUS <= IR when (TB = 2) else
                DR when (TB = 5) else
				"0000000" & PC when (TB = 6) else
				"0000000" & XR when (TB = 4) else
				"0000000" & SP when (TB = 3) else
				"0000000" & AR when (TB = 7) else 
				"0000000" & SR when (TB = 8) else
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
        elsif FB = 4 then
          XR <= DATA_BUS(11 downto 0);
        end if;
      end if;
    end process;
	
	IR_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				IR <= (others => '0');
			elsif FB = 2 then
				IR <= DATA_BUS;
			end if;
		end if;
	end process;
	
	SR_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				SR <= (others => '0');
			elsif FB = 8 then
				SR <= DATA_BUS(11 downto 0);
			end if;
		end if;
	end process;
    
    SP_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          SP <= (others => '0');
        elsif FB = 3 then
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

    DR_reg : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          DR <= (others => '0');
        elsif FB = 5 then
          DR <= "000000" & DATA_BUS(11 downto 0); -- Ta endast adressfältet
        elsif RW = "10" then -- Läs från minnet
          DR <= p_mem(to_integer(ADR));
        elsif RW = "11" then -- Skriv till minnet
          p_mem(to_integer(ADR)) <= DR;
        end if;
      end if;
    end process;
	
	-- Fungerar som en T vippa.
	-- signalen I används som en spärr för att inte kunna få avbrott under -
	-- ett avbrott.
	I_vippan : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then I <= '0';
			elsif Isig = '1' then I <= not I; 
			end if;
		end if;
	end process;
	
	-- Behöver uM vara en process???? är lite osäker . . .
	-- Tror det eftersom att vi ska kunna köra uPC <= uPC + 1, behövs ju en
	-- vippa i sånna fall fast går ju lösa med kombinatorik också eller?
	
	uPC_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then uPC <= (others => '0');
			elsif (intr_vippa = '1') and (I = '0') then 
				uPC <= intr_vector;
				intr_vippa <= '0';
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
				if C = '0' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 11 then
				if O = '0' then
					uPC <= uAddr;
				else
					uPC <= uPC + 1;
				end if;
			elsif SEQ = 12 then
				uPC <= (others => '0'); -- HALT
			end if; 
		end if;
	end process;

	uM <= u_mem(to_integer(uPC));

    -- Installera K1
	  
	K1_out <= K1_mem(to_integer(IR(18 downto 14)));

    -- Installera K2
	  
	K2_out <= K2_mem(to_integer(IR(13 downto 12)));

    -- Installera ALU
    -- Lägg till funktioner eftersom, finns plats för 16 olika

    ALU_func : process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' 	 then AR <= (others => '0');
        elsif ALUsig = 1 then AR <= AR + 1;
        elsif ALUsig = 2 then AR <= AR - 1;
        elsif ALUsig = 3 then AR <= AR + DATA_BUS(11 downto 0);
        elsif ALUsig = 4 then AR <= AR - DATA_BUS(11 downto 0);
		elsif ALUsig = 5 then AR <= AR and DATA_BUS(11 downto 0);
		elsif ALUsig = 6 then AR <= AR or DATA_BUS(11 downto 0);
		elsif ALUsig = 7 then AR <= AR * 2;   --logical shift left
		elsif ALUsig = 8 then AR <= AR srl 1; --logical shift right
		elsif ALUsig = 9 then AR <= not DATA_BUS(11 downto 0);
		elsif ALUsig = 10 then AR <= (others => '0');
		elsif ALUsig = 11 then AR <= (others => '1');
		elsif ALUsig = 12 then AR <= AR * DATA_BUS(11 downto 0); -- kanske fungerar :)
		elsif FB = 7    then AR <= DATA_BUS(11 downto 0);
        end if;
      end if;
    end process;
	
	-- Flaggornas logik
	-- Måste vara i samma klockpuls som beräkningen i ALU
	-- Behöver vi dom resterande flaggorna?
	
	Z <= '1' when (AR = 0 and ALUsig /= 0) else
		 '0' when (rst = '1') else '0';
		 
	N <= '1' when (AR < 0 and ALUsig /= 0) else
		 '0' when (rst = '1') else '0';
		 
	SR(0) <= Z;
	SR(1) <= N;
	SR(2) <= O;
	SR(3) <= C;
		 
	-- PC funktionalitet
	-- Avbrotts rutinen har bara fått en random adress
	
	PC_func : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				PC <= (others => '0');
			elsif intr = '1' then
				PC <= "000010000000"; -- Hoppa till avbrottsrutin
			elsif FB = 6 then
				PC <= DATA_BUS(11 downto 0);
			elsif SEQ = 13 then -- Vilkorligt hopp N = 1
				if N = '1' then
					PC <= DATA_BUS(11 downto 0);
				end if;
			elsif SEQ = 14 then -- vilkorligt hopp Z = 1
				if Z = '1' then
					PC <= DATA_BUS(11 downto 0);
				end if;
			elsif PCsig = '1' then
				PC <= PC + 1;
			end if;
		end if;
	end process;
    
  end Behavioral;
  
