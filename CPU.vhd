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
  		clk       	:  in std_logic;
   		rst         	:  in std_logic;
   		intr        	:  in std_logic; 				-- Avbrotts nivå 1
		intr2		:  in std_logic;  				-- Avbrotts nivå 2
		intr3		:  in std_logic;				-- Avbrotts nivå 3
		intr_code   	:  in unsigned(3 downto 0); 			-- Vilken typ av avbrott som skett (För att kunna veta vad som orsakat kollision)
		joystick_pos 	:  in unsigned(1 downto 0);			-- Vilken riktning joystick pekar (00 = vänster, 01 = uppåt, 10 = höger, 11 = neråt) : Address $FF8 i minnet
		output1 	:  out unsigned(9 downto 0);   			-- Output 1  : Address $77 i minnet
		output2    	:  out unsigned(9 downto 0);			-- Output 2  : Address $76 i minnet
		output3		:  out unsigned(9 downto 0);			-- Output 3  : Address $71 i minnet
		output4 	:  out unsigned(9 downto 0)    			-- Output 4  : Address $70 i minnet
  	);
end cpu;

architecture Behavioral of cpu is 

  	-- micro memory
  
	type u_mem_t is array(0 to 127) of unsigned(29 downto 0);
	
	-- Skriv mikrominne här

  	constant u_mem_c : u_mem_t := 
		   	   --      ALU _ TB _ FB _P_I_ SEQ_RW_SP_  uAddr
				(b"0000_0110_0001_0_1_0000_00_00_00000000", -- ADR <= PC					0
				 b"0000_0000_0000_0_0_0000_10_00_00000000", -- DR <= MEM(ADR)					1
				 b"0000_0101_0010_0_0_0000_00_00_00000000", -- IR <= DR						2
				 b"0000_0000_0000_1_0_0010_00_00_00000000", -- PC++, uPC <= K2					3
				 -- M = "00" , Direkt addressering
				 b"0000_0010_0001_0_0_0000_00_00_00000000", -- ADR <= IR					4
				 b"0000_0000_0000_0_0_0001_10_00_00000000", -- DR <= MEM(ADR)					5
				 -- M = "01" , Omedelbar operand
				 b"0000_0110_0001_0_0_0000_00_00_00000000", -- ADR <= PC					6
				 b"0000_0000_0000_1_0_0001_10_00_00000000", -- DR <= MEM(ADR), PC++ 				7
				 -- M = "10" , Indirekt addressering
				 b"0000_0010_0001_0_0_0000_00_00_00000000", -- ADR <= IR					8
				 b"0000_0000_0000_0_0_0000_10_00_00000000", -- DR <= MEM(ADR)					9
				 b"0000_0101_0001_0_0_0000_00_00_00000000", -- ADR <= DR					10
				 b"0000_0000_0000_0_0_0001_10_00_00000000", -- DR <= MEM(ADR)					11
				 -- M = "11" , Absolut addresering
				 b"0000_0010_0101_0_0_0001_00_00_00000000", -- DR <= IR						12
				 -- OP = 00000, LDA M,ADDR  , AR <= MEM(ADDR)			
				 b"0000_0101_0111_0_1_0011_00_00_00000000", -- AR <= DR, uPC <= 0				13
				 -- OP = 00001, STXR M,ADDR , MEM(DR) <= XR
				 b"0000_0101_0001_0_0_0000_00_00_00000000", -- ADR <= DR      					14
				 b"0000_0100_0101_0_0_0000_00_00_00000000", -- DR <= XR						15
				 b"0000_0000_0000_0_1_0011_11_00_00000000", -- MEM(ADR) <= XR,uPC <= 0				16
				 -- Avbrottsrutin, Lägg undan alla register i minnet
				 b"0000_0110_0101_0_0_0000_00_00_00000000", -- DR <= PC						17
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--					18
				 b"0000_1000_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= SR 			19
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--					20
				 b"0000_0111_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= AR 			21
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--					22
				 b"0000_0100_0101_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, DR <= XR 			23
				 b"0000_0011_0001_0_0_0000_00_10_00000000", -- ADR <= SP, SP--			   		24
				 b"0000_1001_0110_0_0_0000_11_00_00000000", -- MEM(ADR) <= DR, PC <= IV 			25
				 b"0000_0110_0001_0_0_0000_00_00_00000000", -- ADR <= PC					26	
				 b"0000_0000_1100_0_1_0011_00_00_00000000", -- SR <= IL, uPC <= 0				27
				 -- OP = 0010, RTE , Hoppa ur avbrottet
				 b"0000_0000_0000_0_0_0000_00_01_00000000", -- SP ++						28
				 b"0000_0011_0001_0_0_0000_00_01_00000000", -- ADR <= SP, SP++					29
				 b"0000_0011_0001_0_0_0000_10_01_00000000", -- ADR <= SP,DR<=MEM(ADR),SP++  30
				 b"0000_0101_0100_0_0_0000_10_00_00000000", -- DR <= MEM(ADR), XR <= DR 			31
				 b"0000_0101_0111_0_0_0000_00_00_00000000", -- AR <= DR						32
				 b"0000_0011_0001_0_0_0000_00_01_00000000", -- ADR <= SP, SP++					33
				 b"0000_0011_0001_0_0_0000_10_00_00000000", -- ADR <= SP,DR <= MEM(ADR) 			34
				 b"0000_0101_1000_0_0_0000_10_00_00000000", -- SR <= DR,DR <= MEM(ADR)  			35
				 b"0000_0101_0110_0_0_0000_00_00_00000000", -- PC <= DR						36
				 b"0000_1100_0000_0_1_0011_00_00_00000000", -- IL <= SR						37
				 -- OP = 0011, HALT, Stanna programmet
				 b"0000_0000_0000_0_0_0101_00_00_00100110", -- uPC <= uPC	  				38
				 -- OP = 0100, LDXR M,ADDR, Ladda XR med ADDR
				 b"0000_0101_0100_0_1_0011_00_00_00000000", -- XR <= DR 	               			39
				 -- OP = 0101, JMP M,ADDR, Hoppa till bestämd address
				 b"0000_0101_0110_0_1_0011_00_00_00000000", -- PC <= DR						40
				 -- OP = 0110, ADD M,ADDR, AR <= AR + DR								
				 b"0011_0101_0111_0_1_0011_00_00_00000000", -- AR <= AR + DR 					41
				 -- OP = 0111, MULP M,ADDR, AR <= AR * DR (Multiplikation),
				 b"1010_0101_0111_0_1_0011_00_00_00000000", -- AR <= AR * DR					42
				 -- OP = 1000, SUB M,ADDR, AR <= AR - DR
				 b"0100_0101_0111_0_1_0011_00_00_00000000", -- AR <= AR - DR					43
				 -- OP = 1001, STORE M,ADDR, MEM(ADDR) <= AR
				 b"0000_0111_0101_0_0_0000_00_00_00000000", -- DR <= AR						44
				 b"0000_0000_0000_0_1_0011_11_00_00000000", -- MEM(ADDR) <= DR					45
				 -- OP = 1010, EQU M,ADDR , AR == MEM(ADDR)
				 b"0100_0100_0111_0_0_0000_00_00_00000000", -- AR <= AR - XR					46
				 b"0000_0000_0000_0_0_0000_00_00_00000000", -- Blank rad för ladda Z				47
				 b"0000_0000_0000_0_0_0110_00_00_00110010", --							48
				 b"0000_0000_0000_0_1_0011_00_00_00000000", -- uPC <= 0						49
				 b"0000_0010_0110_0_1_0011_00_00_00000000", -- PC <= IR, uPC <= 0				50
				 -- OP = 1011, NEQU M,ADDR , AR != MEM(ADDR)
				 b"0100_0100_0111_0_0_0000_00_00_00000000", -- AR <= AR - XR					51
				 b"0000_0000_0000_0_0_0000_00_00_00000000", -- Blank rad för ladda Z				52
				 b"0000_0000_0000_0_0_0100_00_00_00110111", --							53
				 b"0000_0000_0000_0_1_0011_00_00_00000000", -- uPC <= 0						54
				 b"0000_0010_0110_0_1_0011_00_00_00000000", -- PC <= IR, uPC <= 0				55
				 -- OP = 1100, LDV1 M,ADDR , IV1 <= MEM(ADDR)
				 b"0000_0101_1010_0_1_0011_00_00_00000000", -- IV1 <= MEM(ADDR)					56
				 -- OP = 1101, LDV2 M,ADDR , IV2 <= MEM(ADDR)
				 b"0000_0101_1011_0_1_0011_00_00_00000000", -- IV2 <= MEM(ADDR)					57
				 -- OP = 1110, LDSP M,ADDR , SP <= MEM(ADDR)
				 b"0000_0101_0011_0_1_0011_00_00_00000000", -- SP <= MEM(ADDR)					58
				 -- OP = 1111, SLEEP M,ADDR , LOOPA MEM(ADDR) GGR
				 b"0000_0101_0111_0_0_0000_00_00_00000000", -- AR <= DR						59
				 b"0000_0000_0000_0_0_0000_00_00_00000000", -- BLANK RAD					60
				 b"0010_0000_0000_0_0_0100_00_00_00111101", -- AR <= AR - 1					61
				 b"0000_0000_0000_0_1_0011_00_00_00000000", -- uPC <= 0						62
				 -- OP = 10000, LDJOY M,ADDR , AR <= JOY
				 b"0000_1101_0111_0_1_0011_00_00_00000000", -- AR <= JOY					63
				 -- OP = 10001, SLEEP_LONG M,ADDR , SLEEP ADDR times
				 b"0000_0101_0111_0_0_0000_00_00_00000000", -- AR <= DR						64
				 b"0000_0101_0100_0_0_0000_00_00_00000000", -- XR <= DR						65
				 b"0010_0000_0000_0_0_0100_00_00_01000010", -- AR <= AR - 1					66
				 b"0000_0100_0111_0_0_0000_00_00_00000000", -- AR <= XR						67
				 b"0010_0000_0000_0_0_0000_00_00_00000000", -- AR <= AR - 1					68
				 b"0000_0111_0100_0_0_0110_00_00_01000111", -- XR <= AR 					69
				 b"0000_0101_0111_0_0_0101_00_00_01000010", -- AR <= DR  ,  uPC <= 66 				70
				 b"0000_0000_0000_0_1_0011_00_00_00000000", -- uPC <= 0						71
				 -- OP = 10010, LDIC M,ADDR , XR <= IC
				 b"0000_1110_0100_0_1_0011_00_00_00000000", -- XR <= IC						72
				 -- OP = 10011, LDV3 M,ADDR , IV3 <= DR	
				 b"0000_0101_1111_0_1_0011_00_00_00000000", -- IV3 <= DR					73 
				 -- OP = 10100, AND M,ADDR AR <= AR AND DATA_BUS						
				 b"0101_0101_0111_0_1_0011_00_00_00000000", -- AR <= AR AND DR					74
				 -- OP = 10101, ADD_RND M,ADDR , AR <= AR + RN
				 b"1111_0000_0000_0_1_0011_00_00_00000000", -- AR <= AR + RN					75
				 -- OP = 10110, ADD_X M,ADDR   , SPECIAL FUNKTION, KOLLA ALU:n, ALUsig = 13
				 b"1101_0101_0111_0_1_0011_00_00_00000000", --							76
				 -- OP = 10111, ADD_Y M,ADDR   , SPECIAL FUNKTION, KOLLA ALU:n, ALUsig = 14
				 b"1110_0101_0111_0_1_0011_00_00_00000000", -- 							77				 
				 others => (others => '1'));

	signal u_mem : u_mem_t := u_mem_c;

  	signal uM    : unsigned(29 downto 0) := (others => '0');        -- micro memory output
 	signal uPC   : unsigned(7 downto 0)  := (others => '0');        -- micro program counter

 	 -- Signaler i uM
 	signal uAddr : unsigned(7 downto 0)  := (others => '0');       	-- micro Adress
 	signal TB    : unsigned(3 downto 0)  := (others => '0');        -- to bus field
	signal FB    : unsigned(3 downto 0)  := (others => '0');	-- from bus field
	signal ALUsig   : unsigned(3 downto 0) := (others => '0');
 	signal Isig  : std_logic := '0';                   		-- block interrupts
  	signal RW    : unsigned(1 downto 0) := (others => '0');         -- Read/write
  	signal SEQ   : unsigned(3 downto 0) := (others => '0');
	signal SPsig : unsigned(1 downto 0) := (others => '0');         -- Manipulera stackpekaren
 	signal PCsig : std_logic  := '0';                    		-- PC++
  	signal I     : std_logic := '0'; 				-- T-vippa
  
	signal intr_1: std_logic := '0';
	signal intr_2: std_logic := '0';
	signal intr_3: std_logic := '0';
  
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
					   "00001100", --Absolut addressering
					   others => (others => '1')); 
  
	signal K2_mem : K2_mem_t := K2_mem_c;
  
	-- K1 minne
  
	type K1_mem_t is array(0 to 31) of unsigned(7 downto 0);
  
	-- Skriv K1 minne nedanför
	constant K1_mem_c : K1_mem_t := 
				("00001101", -- LDA   13
				 "00001110", -- STXR  14
				 "00011100", -- RTE   28
				 "00100110", -- HALT  37
				 "00100111", -- LDXR  38
				 "00101000", -- JMP   39
				 "00101001", -- ADD   40
				 "00101010", -- MULP  41
				 "00101011", -- SUB   42
				 "00101100", -- STORE 43
				 "00101110", -- EQU   45
				 "00110011", -- NEQU  50
				 "00111000", -- LDV1  55
				 "00111001", -- LDV2  56
				 "00111010", -- LDSP  57
				 "00111011", -- SLEEP 59
				 "00111111", -- LDJOY 63
				 "01000000", -- SLEEP_LONG 64
				 "01001000", -- LDIC 72
				 "01001001", -- LDV3 73
				 "01001010", -- AND  74
				 "01001011", -- ADD_RND 75
				 "01001100", -- ADD_X 76
				 "01001101", -- ADD_Y 77
				 others => (others => '1')); 
  
	signal K1_mem : K1_mem_t := K1_mem_c; 
  
	-- program memory
  
	type p_mem_t is array(0 to 127) of unsigned(18 downto 0);
  
	-- Skriv program minne här 
	constant p_mem_c : p_mem_t :=  
			-- OP   _ M_        ADDR
			(b"01100_11_000000111001", -- 0  LDV1  11,57	   	 UPPDATERA ADDRESSERNA
			 b"01101_11_000000110000", -- 1  LDV2  11,48    	 UPPDATERA ADDRESSERNA
			 b"10011_11_000000101001", -- 2  LDV3  11,41		 UPPDATERA ADDRESSERNA
			 b"01110_11_000001111111", -- 3  LDSP  11,$07F		 
			 b"00000_11_000000100000", -- 4	 LDA   11,$020		 
			 b"01001_00_000001110110", -- 5	 STORE 00,PacMan_X
			 b"01001_00_000001110101", -- 6  STORE 00,PacMan_Y
			 b"00000_11_000100110000", -- 7  LDA   11,GHOST_START_X
			 b"01001_00_000001110000", -- 8  STORE 00,GHOST_X
			 b"00000_11_000011100000", -- 9  LDA   11,GHOST_START_Y
			 b"01001_00_000001101111", -- 10 STORE 00,GHOST_Y
			 b"00000_11_000000000001", -- 11 LDA   11,$001
			 b"01001_00_000001101110", -- 12 STORE 00,GHOST_DIR
			 b"00000_11_000000000000", -- 13 LDA   11,$000
			 b"01001_00_000001101101", -- 14 STORE 00,GHOST_SPEED
			 b"10000_11_000000000000", -- 15 LDJOY 11,$000			LOAD_JOYSTICK
			 b"01001_00_000001110100", -- 16 STORE 00,PacMan_DIR
			 b"00100_00_000001110011", -- 17 LDXR  00,PacMan_SPEED
			 b"00000_00_000001110110", -- 18 LDA   00,PacMan_X		START_PAC_ADD
			 b"10110_00_000001110100", -- 19 ADD_X 00,PacMan_DIR
			 b"01001_00_000001110110", -- 20 STORE 00,PacMan_X
			 b"00000_00_000001110101", -- 21 LDA   00,PacMan_Y
			 b"10111_00_000001110100", -- 22 ADD_Y 00,PacMan_DIR
			 b"01001_00_000001110101", -- 23 STORE 00,PacMan_Y		END_PAC_ADD
			 b"00100_00_000001101101", -- 24 LDXR  00,GHOST_SPEED		START_GHOST_ADD
			 b"00000_00_000001110000", -- 25 LDA   00,GHOST_X
			 b"10110_00_000001101110", -- 26 ADD_X 00,GHOST_DIR
			 b"01001_00_000001110000", -- 27 STORE 00,GHOST_X
			 b"00000_00_000001101111", -- 28 LDA   00,GHOST_Y
			 b"10111_00_000001101110", -- 29 ADD_Y 00,GHOST_DIR
			 b"01001_00_000001101111", -- 30 STORE 00,GHOST_Y
			 b"10001_11_011000011111", -- 31 SLEEP_LONG 11,$61F		SLEEP
			 b"00000_00_000001110110", -- 32 LDA   00,PacMan_X
			 b"01001_00_000001110010", -- 33 STORE 00,PacMan_Old_X
			 b"00000_00_000001110101", -- 34 LDA   00,PacMan_Y
			 b"01001_00_000001110001", -- 35 STORE 00,PacMan_Old_Y
			 b"00000_00_000001110000", -- 36 LDA   00,GHOST_X
			 b"01001_00_000001101100", -- 37 STORE 00,GHOST_OLD_X
			 b"00000_00_000001101111", -- 38 LDA   00,GHOST_Y
			 b"01001_00_000001101011", -- 39 STORE 00,GHOST_OLD_Y
 			 b"00101_11_000000001111", -- 40 JMP   11,$00F			JUMP TO LOAD_JOYSTICK
			 b"00000_11_000000000000", -- 41 LDA   11,$000			AVBROTT 3 STANNA PACMAN
			 b"01001_00_000001110011", -- 42 STORE 00,PacMan_Speed
			 b"00000_00_000001110010", -- 43 LDA   00,PacMan_Old_X
 			 b"01001_00_000001110110", -- 44 STORE 00,PacMan_X
			 b"00000_00_000001110001", -- 45 LDA   00,PacMan_Old_Y
 			 b"01001_00_000001110101", -- 46 STORE 00,PacMan_Y
			 b"00010_00_000000000000", -- 47 RTE
			 b"00000_00_000001101110", -- 48 LDA   00,GHOST_DIR		AVBROTT 2 ÄNDRA RIKTNING GHOST
			 b"00110_11_000000000101", -- 49 ADD   11,$005
			 b"10100_11_000000000011", -- 50 AND   11,$FFC
			 b"01001_00_000001101110", -- 51 STORE 00,GHOST_DIR
			 b"00000_00_000001101100", -- 52 LDA   00,GHOST_OLD_X
			 b"01001_00_000001110000", -- 53 STORE 00,GHOST_X
			 b"00000_00_000001101011", -- 54 LDA   00,GHOST_OLD_Y
			 b"01001_00_000001101111", -- 55 STORE 00,GHOST_Y
			 b"00010_00_000000000000", -- 56 RTE	
			 b"00000_11_000000000010", -- 57 LDA   11,$002			AVBROTT 1 STARTA PACMAN
			 b"01001_00_000001110011", -- 58 STORE 00,PacMan_SPEED
			 b"01001_00_000001101101", -- 59 STORE 00,GHOST_SPEED
			 b"00010_00_000000000000", -- 60 RTE
			 others => (others => '0'));

	signal p_mem : p_mem_t := p_mem_c;

	signal DR       	: unsigned(18 downto 0) 		:= (others => '0');     -- Dataregister
	signal ADR      	: unsigned(11 downto 0) 		:= (others => '0');     -- Address register
	signal PC       	: unsigned(11 downto 0) 		:= (others => '0');     -- Program räknaren
	signal IR      	 	: unsigned(18 downto 0) 		:= (others => '0');     -- Instruktion register
	signal XR      		: unsigned(11 downto 0) 		:= (others => '0');     -- XR
	signal SP       	: unsigned(11 downto 0) 		:= (others => '0');     -- Stack pekare, startar på $FFF
	signal IV 	  	: unsigned(11 downto 0)  		:= (others => '0');	-- Avbrotts vektorn, startvärde = 3
	signal IL       	: unsigned(1 downto 0)  		:= (others => '0');     -- Avbrotts nivå
	signal IV1	 	: unsigned(11 downto 0) 		:= (others => '0');  	-- Avbrotts vektor för nivå 1
	signal IV2	  	: unsigned(11 downto 0) 		:= (others => '0');  	-- Avbrotts vektor för nivå 2
	signal IV3		: unsigned(11 downto 0)			:= (others => '0');	-- Avbrotts vektor för nivå 3
	signal IC		: unsigned(11 downto 0)			:= (others => '0');	-- Interruptcode register
	signal SR       	: unsigned(11 downto 0) 		:= (others => '0');     -- Status register
	signal AR       	: unsigned(11 downto 0) 		:= (others => '0');     -- Ackumulator register
	signal DATA_BUS 	: unsigned(18 downto 0) 		:= (others => '0');     -- Bussen 19 bitar
	signal JOY	  	: unsigned(11 downto 0) 		:= (others => '0');	-- Joystickens position
	signal RN		: unsigned(11 downto 0)			:= (others => '0');
	signal OUTPUT_REG1 	: unsigned(9 downto 0) 			:= (others => '0');  
	signal OUTPUT_REG2 	: unsigned(9 downto 0) 			:= (others => '0');  
	signal OUTPUT_REG3 	: unsigned(9 downto 0) 			:= (others => '0');  
	signal OUTPUT_REG4 	: unsigned(9 downto 0) 			:= (others => '0');  
  
	-- Flaggorna

	signal Z : std_logic := '0';

begin 

	-- Installera output signalerna
	-- Output registren

	output1 <= OUTPUT_REG1;
	output2 <= OUTPUT_REG2;
	output3 <= OUTPUT_REG3;
	output4 <= OUTPUT_REG4;
	
	output_regs : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				OUTPUT_REG1 <= (others => '0');
				OUTPUT_REG2 <= (others => '0');
				OUTPUT_REG3 <= (others => '0');
				OUTPUT_REG4 <= (others => '0');
			elsif ADR = 118 and RW = "11" then
				OUTPUT_REG1 <= DR(9 downto 0); -- $76
			elsif ADR = 117 and RW = "11" then
				OUTPUT_REG2 <= DR(9 downto 0); -- $75
			elsif ADR = 112 and RW = "11" then
				OUTPUT_REG3 <= DR(9 downto 0); -- $70
			elsif ADR = 111 and RW = "11" then
				OUTPUT_REG4 <= DR(9 downto 0); -- $6F
			end if;
		end if;
	end process;

	-- Installera joystickens register

	joystick_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then 	JOY <= (others => '0');
			elsif FB = 13 then	JOY <= DATA_BUS(11 downto 0);
			else 			JOY <= "0000000000" & joystick_pos;				
			end if;
		end if;
	end process;
  
	-- Installera avbrotts vippor
	
	intr_vippor : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				intr_1 <= '0';
				intr_2 <= '0';
				intr_3 <= '0';
			elsif intr = '1' or intr2 = '1' or intr3 = '1' then
				if intr = '1' then 
					intr_1 <= '1';
				end if;
				
				if intr2 = '1' then 
					intr_2 <= '1';
				end if;

				if intr3 = '1' then 
					intr_3 <= '1';
				end if;
			end if;
			
			if    intr_3 = '1' and I = '0' and IL < 3 then
				intr_3 <= '0';
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
		"0000000" & PC  when (TB = 6)  	else
		"0000000" & XR  when (TB = 4)  	else
		"0000000" & SP  when (TB = 3)  	else
		"0000000" & AR  when (TB = 7)  	else 
		"0000000" & SR  when (TB = 8)  	else
		"0000000" & IV  when (TB = 9)  	else
		"0000000" & IV1 when (TB = 10) 	else
		"0000000" & IV2 when (TB = 11) 	else
		"0000000" & JOY when (TB = 13)  else
		"0000000" & IC	when (TB = 14)  else
		"0000000" & IV3 when (TB = 15)  else
		(others => '0') when (rst = '1')else
		(others => '0');


	-- Ett register som alltid innehåller ett random tal

	RN_reg  : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				RN <= (others => '0');
			else
				RN <= RN + 1;
			end if;
		end if;
	end process;

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

	IV3_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				IV3 <= (others => '0');
			elsif FB = 15 then
				IV3 <= DATA_BUS(11 downto 0);
			end if;
		end if;
	end process;

	--intr_code:s register

	IC_reg : process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				IC <= (others => '0');
			elsif FB = 14 then
				IC <= DATA_BUS(11 downto 0);
			else
				IC <= "00000000" & intr_code; 
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
			elsif intr_3 = '1' and I = '0' and IL < 3 then
				IL <= "11";
			elsif intr_2 = '1' and I = '0' and IL < 2 then
				IL <= "10";
			elsif intr_1 = '1' and I = '0' and IL < 1 then
				IL <= "01";
			end if;
		end if;
	end process;
	
	IV <= (others => '0') 		when (rst = '1') else
		  (others => '0') 	when (IL = 0)    else
		  IV1 			when (IL = 1)    else
		  IV2 			when (IL = 2)    else 
		  IV3			when (IL = 3)    else (others => '0');	

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
			elsif AR = 0 then 
				SR(11) <= '1'; -- Sätt Z flaggan
			else
				SR(11) <= '0';
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
			elsif I = '0' and ((intr_1 = '1' and IL < 1) or (intr_2 = '1' and IL < 2) or (intr_3 = '1' and IL < 3))  then uPC <= intr_vector;
			elsif SEQ = 1 then uPC <= K1_out;
			elsif SEQ = 2 then uPC <= K2_out;
			elsif SEQ = 3 then uPC <= (others => '0');
			elsif SEQ = 5 then uPC <= uAddr;
			elsif SEQ = 4 and Z = '0' then uPC <= uAddr;
			elsif SEQ = 6 and Z = '1' then uPC <= uAddr;
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
			if rst = '1' 	 then 
				AR <= (others => '0');
			elsif ALUsig = 1 then 
				AR <= AR + 1;
			elsif ALUsig = 2 then 
				AR <= AR - 1;
			elsif ALUsig = 3 then 
				AR <= AR + DATA_BUS(11 downto 0);
			elsif ALUsig = 4 then 
				AR <= AR - DATA_BUS(11 downto 0);
			elsif ALUsig = 5 then 
				AR <= AR and DATA_BUS(11 downto 0);
			elsif ALUsig = 6 then 
				AR <= AR or DATA_BUS(11 downto 0);
			elsif ALUsig = 7 then 
				AR <= AR(10 downto 0) & '0';   --logical shift left
			elsif ALUsig = 8 then 
				AR <= '0' & AR(11 downto 1);   --logical shift right
			elsif ALUsig = 9 then 
				AR <= not DATA_BUS(11 downto 0);
			elsif ALUsig = 10 then 
				AR <= (others => '0');
			elsif ALUsig = 11 then 
				AR <= (others => '1');
			elsif ALUsig = 12 then 
				AR <= AR(5 downto 0) * DATA_BUS(5 downto 0);
			elsif ALUsig = 13 then -- Speciella funktioner för att plussa på joystickens riktning direkt på en X-koordinat
				if ((not DATA_BUS(1)) and (not DATA_BUS(0))) = '1' then 
					AR <= AR - XR;
				elsif ((not DATA_BUS(0)) and DATA_BUS(1)) = '1'	then 
					AR <= AR + XR;
				end if;
			elsif ALUsig = 14 then -- Speciella funktioner för att plussa på joystickens riktning direkt på en Y-koordinat
				if ((not DATA_BUS(1)) and DATA_BUS(0)) = '1' then
					AR <= AR - XR;
				elsif (DATA_BUS(1) and DATA_BUS(0)) = '1' then
					AR <= AR + XR;
				end if;
			elsif ALUsig = 15 then -- Plussa på ett helt random tal
				AR <= AR + RN;
			elsif FB = 7 then 
				AR <= DATA_BUS(11 downto 0);
			end if;
		end if;
	end process;
		 
	-- Sätt flaggorna 	 
	
	Z <= SR(11);
		 
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
  
