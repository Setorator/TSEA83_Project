-- Detta är en CPU av Olle roos typ med avbrott
-- Alla register förrutom DR och IR är 12 bitar breda, DR och IR är 19
-- Program minnet är 19 bitar brett
-- Bussen är 19 bitar brett
-- Mikrominnet är 28 bitar brett
-- Signaler som kan användas fast inte går mellan buss och
-- register nås genom att endast ange FB
-- TR och HR är register som är bortagna då vi inte kommer att behöva dom


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- CPU Interface

entity cpu is 
  port (
    clk         :  in std_logic;
    rst         :  in std_logic;
    intr        :  in std_logic; 				-- Avbrotts nivå 1
	intr2		:  in std_logic;  				-- Avbrotts nivå 2
	intr_code   :  in unsigned(3 downto 0); 	-- Vilken typ av avbrott som skett (För att kunna veta vad som orsakat kollision)
	joystick_poss : in unsigned(1 downto 0);	-- Vilken riktning joystick pekar (00 = vänster, 01 = uppåt, 10 = höger, 11 = neråt) : Address $FF8 i minnet
	output1 	:  out unsigned(18 downto 0);   -- Output 1  : Address $FF7 i minnet
	output2     :  out unsigned(18 downto 0);	-- Output 2  : Address $FF6 i minnet
	output3		:  out unsigned(18 downto 0);	-- Output 3  : Address $FF1 i minnet
	output4 	:  out unsigned(18 downto 0)   -- Output 4  : Address $FF0 i minnet
  );
end cpu;

architecture Behavioral of cpu is 

  -- micro memory
  
  type u_mem_t is array(0 to 255) of unsigned(29 downto 0);
  
  -- Skriv mikrominne här
  constant u_mem_c : u_mem_t := 
		   --      ALU _ TB _ FB _P_I_ SEQ_RW_SP_  uAddr
				(b"0000_0110_0001_0_1_0000_00_00_00000000", -- ADR <= PC					0
				 b"0000_0000_0000_0_0_0000_10_00_00000000", -- DR <= MEM(ADR)				1
				 b"0000_0101_0010_0_0_0000_00_00_00000000", -- IR <= DR						2
				 b"0000_0000_0000_1_0_0010_00_00_00000000", -- PC++, uPC <= K2				3
				 -- M = "00" , Direkt addressering
				 b"0000_0010_0001_0_0_0000_00_00_00000000", -- ADR <= IR					4
				 b"0000_0000_0000_0_0_0001_10_00_00000000", -- DR <= MEM(ADR)				5
				 -- M = "01" , Omedelbar operand
				 b"0000_0110_0001_0_0_0000_00_00_00000000", -- ADR <= PC					6
				 b"0000_0000_0000_1_0_0001_10_00_00000000", -- DR <= MEM(ADR), PC++ 		7
				 -- M = "10" , Indirekt addressering
				 b"0000_0010_0001_0_0_0000_00_00_00000000", -- ADR <= IR					8
				 b"0000_0000_0000_0_0_0000_10_00_00000000", -- DR <= MEM(ADR)				9
				 b"0000_0101_0001_0_0_0000_00_00_00000000", -- ADR <= DR					10
				 b"0000_0000_0000_0_0_0001_10_00_00000000", -- DR <= MEM(ADR)				11
				 -- M = "11" , Absolut addresering
				 b"0000_0010_0101_0_0_0001_00_00_00000000", -- DR <= IR						12
				 -- OP = 00000, LDA M,ADDR  , AR <= MEM(ADDR)			
				 b"0000_0101_0111_0_1_0011_00_00_00000000", -- AR <= DR, uPC <= 0			13
				 -- OP = 00001, STXR M,ADDR , MEM(DR) <= XR
				 b"0000_0101_0001_0_0_0000_00_00_00000000", -- ADR <= DR      				14
				 b"0000_0100_0101_0_0_0000_00_00_00000000", -- DR <= XR						15
				 b"0000_0000_0000_0_1_0011_11_00_00000000", -- MEM(ADR) <= XR,uPC <= 0		16
				 -- Avbrottsrutin, Lägg undan alla register i minnet
				 b"0000_0110_0101_0_0_0000_00_00_00000000", -- DR <= PC						17
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--				18
				 b"0000_1000_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= SR 	19
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--				20
				 b"0000_0111_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= AR 	21
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--				22
				 b"0000_0100_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= XR 	23
				 b"0000_0011_0001_0_0_0000_00_00_00000000", -- ADR <= SP			    	24
				 b"0000_1001_0110_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, PC <= IV 	25
				 b"0000_0110_0001_0_0_0000_00_00_00000000", -- ADR <= PC					26	
				 b"0000_0000_1100_0_0_0101_00_00_00000001", -- SR <= IL, uPC <= 1			27
				 -- OP = 0010, RTE , Hoppa ur avbrottet
				 b"0000_0011_0001_0_0_0000_00_01_00000000", -- ADR <= SP, SP++				28
				 b"0000_0011_0001_0_0_0000_10_01_00000000", -- ADR <= SP,DR <= MEM(ADR) 	29
				 b"0000_0101_0100_0_0_0000_10_00_00000000", -- DR <= MEM(ADR), XR <= DR 	30
				 b"0000_0101_0111_0_0_0000_00_00_00000000", -- AR <= DR						31
				 b"0000_0011_0001_0_0_0000_00_01_00000000", -- ADR <= SP, SP++				32
				 b"0000_0011_0001_0_0_0000_10_00_00000000", -- ADR <= SP,DR <= MEM(ADR) 	33
				 b"0000_0101_1000_0_0_0000_10_00_00000000", -- SR <= DR,DR <= MEM(ADR)  	34
				 b"0000_0101_0110_0_0_0000_00_00_00000000", -- PC <= DR						35
				 b"0000_1100_0000_0_1_0011_00_00_00000000", -- IL <= SR						36
				 -- OP = 0011, HALT, Stanna programmet
				 b"0000_0000_0000_0_0_0101_00_00_00100101", -- uPC <= uPC	  				37
				 -- OP = 0100, LDXR M,ADDR, Ladda XR med ADDR
				 b"0000_0101_0100_0_1_0011_00_00_00000000", -- XR <= DR 	                38
				 -- OP = 0101, JMP M,ADDR, Hoppa till bestämd address
				 b"0000_0101_0110_0_1_0011_00_00_00000000", -- PC <= DR						39
				 -- OP = 0110, ADD M,ADDR, AR <= AR + DR								
				 b"0011_0101_0111_0_1_0011_00_00_00000000", -- AR <= AR + DR 				40
				 -- OP = 0111, MULP M,ADDR, AR <= AR * DR (Multiplikation),
				 b"1010_0101_0111_0_1_0011_00_00_00000000", -- AR <= AR * DR				41
				 -- OP = 1000, SUB M,ADDR, AR <= AR - DR
				 b"0100_0101_0111_0_1_0011_00_00_00000000", -- AR <= AR - DR				42
				 -- OP = 1001, STORE M,ADDR, MEM(ADDR) <= AR
				 b"0000_0111_0101_0_0_0000_00_00_00000000", -- DR <= AR						43
				 b"0000_0000_0000_0_1_0011_11_00_00000000", -- MEM(ADDR) <= DR				44
				 -- OP = 1010, EQU M,ADDR , AR == MEM(ADDR)
				 b"0100_0100_0111_0_0_0000_00_00_00000000", -- AR <= AR - XR				45
				 b"0000_0000_0000_0_0_0110_00_00_00110000", --								46
				 b"0000_0000_0000_0_1_0011_00_00_00000000", -- uPC <= 0						47
				 b"0000_0010_0110_0_1_0011_00_00_00000000", -- PC <= IR, uPC <= 0			48
				 -- OP = 1011, NEQU M,ADDR , AR != MEM(ADDR)
				 b"0100_0100_0111_0_0_0000_00_00_00000000", -- AR <= AR - XR				49
				 b"0000_0000_0000_0_0_0100_00_00_00110100", --								50
				 b"0000_0000_0000_0_1_0011_00_00_00000000", -- uPC <= 0						51
				 b"0000_0010_0110_0_1_0011_00_00_00000000", -- PC <= IR, uPC <= 0			52
				 -- OP = 1100, LDV1 M,ADDR , IV1 <= MEM(ADDR)
				 b"0000_0101_1010_0_1_0011_00_00_00000000", -- IV1 <= MEM(ADDR)				53
				 -- OP = 1101, LDV2 M,ADDR , IV2 <= MEM(ADDR)
				 b"0000_0101_1011_0_1_0011_00_00_00000000", -- IV2 <= MEM(ADDR)				54
				 -- OP = 1110, LDSP M,ADDR , SP <= MEM(ADDR)
				 b"0000_0101_0011_0_1_0011_00_00_00000000", -- SP <= MEM(ADDR)				55
				 others => (others => '0'));

  signal u_mem : u_mem_t := u_mem_c;

  signal uM    : unsigned(29 downto 0) := (others => '0');        -- micro memory output
  signal uPC   : unsigned(7 downto 0) := (others => '0');         -- micro program counter

  -- Signaler i uM
  signal uAddr : unsigned(7 downto 0)    := (others => '0');         -- micro Adress
  signal TB    : unsigned(3 downto 0)    := (others => '0');         -- to bus field
  signal FB    : unsigned(3 downto 0)    := (others => '0');          -- from bus field
  signal ALUsig   : unsigned(3 downto 0) := (others => '0');
  signal Isig  : std_logic := '0';                   			   -- block interrupts
  signal RW    : unsigned(1 downto 0)  := (others => '0');          -- Read/write
  signal SEQ   : unsigned(3 downto 0)  := (others => '0');
  signal SPsig : unsigned(1 downto 0)  := (others => '0');         -- Manipulera stackpekaren
  signal PCsig : std_logic  := '0';                    			   -- PC++
  signal I     : std_logic := '0'; 				   				   -- T-vippa
  
  signal intr_1: std_logic := '0';
  signal intr_2: std_logic := '0';
  
  -- K1 out

  signal K1_out : unsigned(7 downto 0) := (others => '0');

  -- K2 out

  signal K2_out : unsigned(7 downto 0) := (others => '0');
  
  -- K2 minne
  
  type K2_mem_t is array(0 to 3) of unsigned(7 downto 0);
  
  constant intr_vector : unsigned(7 downto 0) := "00010001"; -- 17
  
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
				("00001101", -- LDA   13
				 "00001110", -- STXR  14
				 "00011100", -- RTE   28
				 "00100101", -- HALT  37
				 "00100110", -- LDXR  38
				 "00100111", -- JMP	  39
				 "00101000", -- ADD   40
				 "00101001", -- MULP  41
				 "00101010", -- SUB   42
				 "00101011", -- STORE 43
				 "00101101", -- EQU   45
				 "00110001", -- NEQU  49
				 "00110101", -- LDV1  53
				 "00110110", -- LDV2  54
				 "00110111", -- LDSP  55
				others => (others => '0')); 
  
  signal K1_mem : K1_mem_t := K1_mem_c; 
  
  -- program memory
  
  type p_mem_t is array(0 to 4095) of unsigned(18 downto 0);
  
  -- Skriv program minne här 
  constant p_mem_c : p_mem_t :=  
			-- OP   _ M_        ADDR
			(b"01100_11_000000011100", -- 0  LDV1  11,$01C
			 b"01101_11_000000011111", -- 1  LDV2  11,31
			 b"01110_11_111111111111", -- 2  LDSP  11,$FFF
			 b"00100_00_111111110101", -- 3  LDXR  00,PacMan_dir
			 b"00000_11_000000000000", -- 4  LDA   11,left
			 b"01011_11_000000001010", -- 5  NEQU  11,TEST_UP
			 b"00000_00_111111110111", -- 6  LDA   00,PacMan_X
			 b"01000_00_111111110100", -- 7  SUB   00,PacMan_Speed
			 b"01001_00_111111110111", -- 8  STORE 00,PacMan_X
			 b"00101_11_000000011011", -- 9  JMP   11,NEXT_STEP
			 b"00000_11_000000000001", -- 10 LDA   11,up
			 b"01011_11_000000010000", -- 11 NEQU  11,TEST_RIGHT
			 b"00000_00_111111110110", -- 12 LDA   00,PacMan_Y
			 b"01000_00_111111110100", -- 13 SUB   00,PacMan_Speed
			 b"01001_00_111111110110", -- 14 STORE 00,PacMan_Y
			 b"00101_11_000000011011", -- 15 JMP   11,NEXT_STEP
			 b"00000_01_000000000010", -- 16 LDA   01,right
			 b"01011_11_000000010110", -- 17 NEQU  11,TEST_DOWN
			 b"00000_00_111111110111", -- 18 LDA   00,PacMan_X
			 b"00110_00_111111110100", -- 19 ADD   00,PacMan_Speed
			 b"01001_00_111111110111", -- 20 STORE 00,PacMan_X
			 b"00101_11_000000011011", -- 21 JMP   11,NEXT_STEP
			 b"00000_11_000000000011", -- 22 LDA   01,down
			 b"01011_11_000000011011", -- 23 NEQU  11,NEXT_STEP
			 b"00000_00_111111110110", -- 24 LDA   00,PacMan_Y
			 b"00110_00_111111110100", -- 25 ADD   00,PacMan_Speed
			 b"01001_00_111111110110", -- 26 STORE 00,PacMan_Y
			 b"00101_11_000000000011", -- 27 JMP   11,$003
			 b"00000_11_000000000000", -- 28 LDA   11,$000
			 b"01001_00_111111110100", -- 29 STORE 00,PacMan_Speed
			 b"00010_00_000000000000", -- 30 RTE
			 b"00000_11_000000000001", -- 31 LDA 11,$001
			 b"01001_00_111111110100", -- 32 STORE 00,PacMan_Speed
			 b"00010_00_000000000000", -- 33 RTE
			 others => (others => '0'));

  signal p_mem : p_mem_t := p_mem_c;

  signal DR       : unsigned(18 downto 0) := (others => '0');     -- Dataregister
  signal ADR      : unsigned(11 downto 0) := (others => '0');     -- Address register
  signal PC       : unsigned(11 downto 0) := (others => '0');     -- Program räknaren
  signal IR       : unsigned(18 downto 0) := (others => '0');     -- Instruktion register
  signal XR       : unsigned(11 downto 0) := (others => '0');     -- XR
  signal SP       : unsigned(11 downto 0) := (others => '0');     -- Stack pekare, startar på $FFF
  signal IV 	  : unsigned(11 downto 0) := (others => '0');	  -- Avbrotts vektorn, startvärde = 3
  signal IL       : unsigned(1 downto 0)  := (others => '0');     -- Avbrotts nivå
  signal IV1	  : unsigned(11 downto 0) := (others => '0');     -- Avbrotts vektor för nivå 1
  signal IV2	  : unsigned(11 downto 0) := (others => '0');     -- Avbrotts vektor för nivå 2
  signal SR       : unsigned(11 downto 0) := (others => '0');     -- Status register
  signal AR       : unsigned(11 downto 0) := (others => '0');     -- Ackumulator register
  signal DATA_BUS : unsigned(18 downto 0) := (others => '0');     -- Bussen 19 bitar
  
  -- Flaggorna
  
  signal N : std_logic := '0';
  signal Z : std_logic := '0';
  signal O : std_logic := '0';
  signal C : std_logic := '0';

begin 

	-- Installera output signalerna samt joysticks riktning, ska vara klockade
	
	signals_IO : process(clk)
	begin
		if rising_edge(clk) then
			p_mem(4088) <= "00000000000000000" & joystick_poss; --$FF8
			output1 <= p_mem(4087); 	--$FF7
			output2 <= p_mem(4086); 	--$FF6
			p_mem(4085) <= "00000000000000000" & joystick_poss; --$FF5 , PacMan direction = Joystick direction
			output3 <= p_mem(4081); 	--$FF1
			output4 <= p_mem(4080); 	--$FF0
		end if;
	end process;
  
	-- Installera avbrotts vippor
	
	intr_vippor : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				intr_1 <= '0';
			elsif intr = '1' or intr2 = '1' then
				if intr = '1' then intr_1 <= '1';
				end if;
				
				if intr2 = '1' then intr_2 <= '1';
				end if;
			elsif intr_2 = '1' and I = '0' and IL < 2 then
				intr_2 <= '0';
			elsif intr_1 = '1' and I = '0' and IL < 1 then
				intr_1 <= '0';
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
				"0000000" & IV when (TB = 9) else
				"0000000" & IV1 when (TB = 10) else
				"0000000" & IV2 when (TB = 11) else
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
	
	IV1_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				IV1 <= (others => '0');
			elsif FB = 10 then
				IV1 <= DATA_BUS(11 downto 0);
			end if;
		end if;
	end process;
	
	IV2_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				IV2 <= (others => '0');
			elsif FB = 11 then
				IV2 <= DATA_BUS(11 downto 0);
			end if;
		end if;
	end process;
	
	-- Logiken för Interrupt vector registret
		  
	IL_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then 
				IL <= "00";
			elsif TB = 12 then
				IL <= SR(1 downto 0);
			elsif intr_2 = '1' and I = '0' and IL < 2 then
				IL <= "10";
			elsif intr_1 = '1' and I = '0' and IL < 1 then
				IL <= "01";
			end if;
		end if;
	end process;
	
	IV <= (others => '0') when (rst = '1') else
		  (others => '0') when (IL = 0)    else
		  IV1 			  when (IL = 1)    else
		  IV2 			  when (IL = 2)    else IV;

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
			elsif FB = 12 then
				SR(1 downto 0) <= IL;
			else
				-- Sätt O och C flaggorna
				if ((ALUsig = 1) and (AR = 4095)) then
					SR(9) <= '1';
				elsif ((ALUsig = 2) and (AR = 0)) then
					SR(9) <= '1';
				elsif ((ALUsig = 3) and (to_integer(AR) + to_integer(DATA_BUS(11 downto 0)) > 4095)) then
					SR(9) <= '1';  -- Orsakade AR + DATA_BUS spill?
				elsif ((ALUsig = 4) and (to_integer(AR) < to_integer(DATA_BUS(11 downto 0)))) then
					SR(9) <= '1';  -- Orsakade AR - DATA_BUS spill?
				else
					SR(9) <= '0';
				end if;
				
				if ALUsig = 7 then
					SR(8) <= AR(11);
				elsif ALUsig = 8 then
					SR(8) <= AR(0);
				else
					SR(8) <= '0';
				end if;
				
				-- Sätt Z flaggan
				if AR = 0 then
					SR(11) <= '1';
				else
					SR(11) <= '0';
				end if;
				
				--Sätt N flaggan
				if AR < 0 then
					SR(10) <= '1';
				else
					SR(10) <= '0';
				end if;
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
          DR <= "0000000" & DATA_BUS(11 downto 0); -- Ta endast adressfältet
		elsif RW = "10" then -- Läs från minnet
          DR <= p_mem(to_integer(ADR));
		end if;
		
        if RW = "11" then -- Skriv till minnet
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
	
	uPC_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then uPC <= (others => '0');
			elsif I = '0' and ((intr_1 = '1' and IL < 1) or (intr_2 = '1' and IL < 2))  then uPC <= intr_vector;
			elsif SEQ = 1 then uPC <= K1_out;
			elsif SEQ = 2 then uPC <= K2_out;
			elsif SEQ = 3 then uPC <= (others => '0');
			elsif SEQ = 5 then uPC <= uAddr;
			elsif SEQ = 4 and Z = '0' then uPC <= uAddr;
			elsif SEQ = 6 and Z = '1' then uPC <= uAddr;
			elsif SEQ = 7 and N = '1' then uPC <= uAddr;
			elsif SEQ = 8 and C = '1' then uPC <= uAddr;
			elsif SEQ = 9 and O = '1' then uPC <= uAddr;
			elsif SEQ = 10 and C = '0' then uPC <= uAddr;
			elsif SEQ = 11 and O = '0' then uPC <= uAddr;
			elsif SEQ = 12 then uPC <= "00100110"; -- HALT
			else uPC <= uPC + 1;
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
		elsif ALUsig = 7 then AR <= AR(10 downto 0) & '0';   --logical shift left
		elsif ALUsig = 8 then AR <= '0' & AR(11 downto 1);   --logical shift right
		elsif ALUsig = 9 then AR <= not DATA_BUS(11 downto 0);
		elsif ALUsig = 10 then AR <= (others => '0');
		elsif ALUsig = 11 then AR <= (others => '1');
		elsif ALUsig = 12 then AR <= AR(5 downto 0) * DATA_BUS(5 downto 0);
		elsif FB = 7      then AR <= DATA_BUS(11 downto 0);
        end if;
      end if;
    end process;
		 
	-- Sätt flaggorna 	 
	
	Z <= SR(11);
	N <= SR(10);
	O <= SR(9);
	C <= SR(8);
		 
	-- PC funktionalitet
	-- Avbrotts rutinen har bara fått en random adress
	
	PC_func : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				PC <= (others => '0');
			elsif FB = 6 then
				PC <= DATA_BUS(11 downto 0);
			elsif PCsig = '1' then
				PC <= PC + 1;
			end if;
		end if;
	end process;
    
  end Behavioral;
  
