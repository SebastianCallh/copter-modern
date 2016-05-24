--CPU

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type



entity CPU is
    port ( clk                 : in std_logic;    -- Systen clock
           collision           : in std_logic;
           reset               : in std_logic;
           player_x            : out integer;
           player_y            : out integer;
           input               : in std_logic;
           new_column          : in std_logic;
           gap                 : out integer := 60;
           height              : out integer := 0;
           terrain_change      : in std_logic;
           speed               : out integer);
    
 
end CPU;


architecture Behavioral of CPU is

  -- Signals that connect to the bus (and the bus itself)
  signal data_bus : std_logic_vector(15 downto 0);
  signal pc : std_logic_vector(15 downto 0) := x"0012";
  signal asr : std_logic_vector(15 downto 0);
  signal alu_input : signed(15 downto 0);
  signal alu_res : std_logic_vector(15 downto 0);
  signal res : std_logic_vector(15 downto 0);
  signal ir : std_logic_vector(31 downto 0);
  signal pmem_asr : std_logic_vector(15 downto 0);
  signal pmem_res : std_logic_vector(15 downto 0);

  -- Registers
  signal reg1 : std_logic_vector(15 downto 0) := "0000000000000011";
  signal reg2 : std_logic_vector(15 downto 0) := "0000000000000001";
  signal reg3 : std_logic_vector(15 downto 0);
  signal reg4 : std_logic_vector(15 downto 0);

  
  -- Micro
  signal micro_instr : std_logic_vector(23 downto 0);
  signal micro_pc : std_logic_vector(7 downto 0) := "00000000";

  -- Interrupt alerts
  signal terrain_prev : std_logic;
  signal terrain_alert : std_logic;
  
  signal input_prev : std_logic;
  signal press_alert : std_logic;
  signal release_alert : std_logic;
  
  signal collision_prev : std_logic;
  signal collision_alert : std_logic;
  
  signal reset_prev : std_logic;
  signal reset_alert : std_logic;

  signal input_release : std_logic;

  -- Move player signals
  signal player_upd_alert : std_logic;
  signal player_upd_counter : integer := 0;

  -- Interrupt states saved
  signal intr_pc : std_logic_vector(15 downto 0);
  signal intr_res : std_logic_vector(15 downto 0);
  signal intr_alu_res : std_logic_vector(15 downto 0);
  signal intr_z : std_logic;
  signal intr_c : std_logic;
  signal intr_n : std_logic;
  signal intr_o : std_logic;  
  signal intr_enable : std_logic := '0';

  
   -- ALU signals
  signal alu_add : std_logic_vector(16 downto 0);
  signal alu_sub : std_logic_vector(16 downto 0);
  signal alu_not : std_logic_vector(15 downto 0);
  signal alu_and : std_logic_vector(15 downto 0);
  signal alu_or : std_logic_vector(15 downto 0);
  signal alu_xor : std_logic_vector(15 downto 0);
  signal alu_mod : std_logic_vector(15 downto 0);

  signal alu_int : integer;

  --ran_gen signals
  signal ran_nr : std_logic_vector(31 downto 0) := (others => '0');
  signal ran_bit : std_logic;
  -- Initial value for new_ran is seed
  signal new_ran : std_logic_vector(31 downto 0) := "10101010001010110010110001010010";
                                                                      
  
  -- Flags
  signal n_flag : std_logic;
  signal z_flag : std_logic;
  signal o_flag : std_logic;
  signal c_flag : std_logic;


  -- Constants (Variables)
  signal x_pos : std_logic_vector(15 downto 0) := x"0004";
  signal y_pos : std_logic_vector(15 downto 0) := x"0005";
  signal height_pos : std_logic_vector(15 downto 0) := x"0007";
  signal gap_pos : std_logic_vector(15 downto 0) := x"0008";

  signal player_upd : std_logic_vector(15 downto 0) := x"000C";
  signal press_pos : std_logic_vector(15 downto 0) := x"000D";
  signal release_pos : std_logic_vector(15 downto 0) := x"000E";
  signal speed_pos : std_logic_vector(15 downto 0) := x"0011";
  signal speed_internal : integer := 1000;

  signal player_speed : integer;

  -- Progress signals
  signal progress : unsigned(15 downto 0) := (others => '0');
  signal progress_counter : integer := 0;  -- updates progress every second
  signal PROGRESS_LATENCY : integer := 10000000;  -- 1/10th second (if clock at 100MHz)

  -- Score signals
  signal score : integer := 0;         -- current score
  signal score_counter : integer := 0;
  signal SCORE_LATENCY : integer := 10000000;  -- 1/10th second (if clock at 100MHz)

  
  -- Alias
  alias TO_BUS : std_logic_vector(3 downto 0) is micro_instr(23 downto 20);     -- to bus
  alias FROM_BUS : std_logic_vector(3 downto 0) is micro_instr(19 downto 16);   -- from bus
  alias P_BIT : std_logic is micro_instr(15);                                   -- p bit
  alias ALU_OP : std_logic_vector(2 downto 0) is micro_instr(14 downto 12);     -- alu_op
  alias SEQ : std_logic_vector(3 downto 0) is micro_instr(11 downto 8);         -- seq
  alias MICRO_ADR : std_logic_vector(7 downto 0) is micro_instr(7 downto 0);    -- micro address

  alias FETCH_NEXT : std_logic is ir(21);
  alias OP_CODE : std_logic_vector(7 downto 0) is ir(31 downto 24);


  -- Interrupt vectors
  constant COLLISION_INTERRUPT_VECTOR : std_logic_vector(15 downto 0) := x"0000";
  constant TERRAIN_CHANGE_INTERRUPT_VECTOR : std_logic_vector(15 downto 0) := x"0001";
  -- Same as coll for now
  constant RESET_INTERRUPT_VECTOR : std_logic_vector(15 downto 0) := x"0000";

  
  -- Player update frequency
  constant PLAYER_UPDATE_LATENCY : integer := 1400000;  -- same as offset for now
  constant ZERO : std_logic_vector(15 downto 0) := x"0000";
  constant ONE : std_logic_vector(15 downto 0) := x"0001";

  
  -- PMEM (Max is 65535 for 16 bit addresses)
  type ram_t is array (0 to 4096) of std_logic_vector(15 downto 0);
  signal pmem : ram_t := (

-- The processed assembly code is pasted here

x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"0000",
x"3420",
x"0000",
x"1620",
x"010d",
x"3420",
x"0001",
x"1620",
x"00f5",
x"3420",
x"0002",
x"1620",
x"013e",
x"4300",
x"3420",
x"0004",
x"1620",
x"0096",
x"3420",
x"0005",
x"1620",
x"00c8",
x"3420",
x"0007",
x"1620",
x"000f",
x"3420",
x"0008",
x"1620",
x"001e",
x"3420",
x"0006",
x"1620",
x"0001",
x"3420",
x"0010",
x"1620",
x"0000",
x"3420",
x"0011",
x"1620",
x"01f4",
x"4800",
x"3420",
x"000c",
x"3620",
x"0001",
x"1F20",
x"0070",
x"3D20",
x"000a",
x"1F20",
x"004a",
x"3320",
x"003e",
x"4720",
x"0000",
x"3420",
x"0013",
x"1720",
x"0001",
x"3420",
x"0011",
x"3620",
x"012c",
x"2320",
x"005a",
x"3420",
x"0011",
x"1B20",
x"000a",
x"3420",
x"0013",
x"3620",
x"000a",
x"2120",
x"003e",
x"3420",
x"0013",
x"1620",
x"0000",
x"3420",
x"0008",
x"3620",
x"0010",
x"2320",
x"003e",
x"3420",
x"0008",
x"1B20",
x"0001",
x"3320",
x"003e",
x"3420",
x"000c",
x"1620",
x"0000",
x"3420",
x"000d",
x"3620",
x"0000",
x"1F20",
x"008a",
x"3420",
x"000e",
x"3620",
x"0000",
x"1F20",
x"00a6",
x"3420",
x"000d",
x"1620",
x"0000",
x"3420",
x"000e",
x"1620",
x"0000",
x"3320",
x"003e",
x"3420",
x"0005",
x"3620",
x"01c2",
x"3920",
x"003e",
x"3420",
x"0010",
x"3620",
x"0005",
x"2120",
x"00c2",
x"3420",
x"0010",
x"1620",
x"0000",
x"3420",
x"0006",
x"3620",
x"0003",
x"1F20",
x"00c2",
x"3420",
x"0006",
x"1720",
x"0001",
x"3320",
x"00c2",
x"3420",
x"0005",
x"3620",
x"0003",
x"2320",
x"003e",
x"3420",
x"0010",
x"3620",
x"0005",
x"2120",
x"00c2",
x"3420",
x"0010",
x"1620",
x"0000",
x"3420",
x"0006",
x"3620",
x"fffd",
x"1F20",
x"00c2",
x"3420",
x"0006",
x"1B20",
x"0001",
x"3320",
x"00c2",
x"3420",
x"0010",
x"1720",
x"0001",
x"3420",
x"0005",
x"1760",
x"0006",
x"3420",
x"000c",
x"1620",
x"0000",
x"4800",
x"3320",
x"003e",
x"3420",
x"0007",
x"3620",
x"0001",
x"1F20",
x"0147",
x"3420",
x"0007",
x"1B20",
x"0001",
x"4800",
x"3B00",
x"3320",
x"003e",
x"3420",
x"0009",
x"1660",
x"0007",
x"3420",
x"0009",
x"1760",
x"0008",
x"3420",
x"0009",
x"3620",
x"0039",
x"3920",
x"014c",
x"3420",
x"0007",
x"1720",
x"0001",
x"4800",
x"3B00",
x"3320",
x"003e",
x"3520",
x"000a",
x"3420",
x"000a",
x"2720",
x"0003",
x"3420",
x"000a",
x"1760",
x"0012",
x"3420",
x"000a",
x"3620",
x"0002",
x"2320",
x"00d1",
x"3420",
x"000a",
x"3620",
x"0003",
x"3920",
x"00df",
x"3320",
x"0146",
x"3420",
x"0003",
x"1620",
x"0001",
x"3420",
x"0007",
x"1620",
x"0000",
x"3420",
x"0008",
x"1620",
x"0041",
x"4800",
x"3420",
x"000a",
x"1620",
x"ffff",
x"3420",
x"000a",
x"3620",
x"0000",
x"1F20",
x"012a",
x"3420",
x"000a",
x"1B20",
x"0001",
x"3320",
x"011e",
x"3420",
x"0008",
x"1620",
x"001e",
x"3420",
x"0007",
x"1620",
x"000f",
x"3420",
x"0005",
x"1620",
x"0014",
x"3420",
x"0011",
x"1620",
x"01f4",
x"4800",
x"3B00",
x"3320",
x"003e",
x"3420",
x"0003",
x"1620",
x"0001",
x"3420",
x"0005",
x"1620",
x"00c8",
x"3B00",
x"3420",
x"0012",
x"1620",
x"0001",
x"3B00",
x"3420",
x"0012",
x"1620",
x"0000",
x"3B00",
x"3320",
x"003e",
x"FF00",



others => "0000000000000000");

  -- micro-MEM (Max is 255 for 8 bit addresses)
  type micro_mem_t is array (0 to 255) of std_logic_vector(23 downto 0);
  signal micro_mem : micro_mem_t := (

-- Here are all the micro programs

    
    "000000000000111101000100",  -- check for interrupts, ASR <= PC
    "000100100000000000000000",  -- asr <= pc
    "001100000000000000000000",  -- fetch instruction (only 16 bits)
    "001101100000000000000000",  -- and check for 32 bit instruction
    
    "000000001000100000010100",  -- if 32 bit fetch next 16, else goto OP
    "000100101000000000000000",  -- asr <= pc, pc++
    "001100000000000000000000",  --             fetch pmem(asr)
    "001101110000000000000000",  -- ir(15 downto 0) <= pmem(asr)
    "000000000000001000000000",  -- 08:check adress mod
    
    "001100000000000000000000",  -- 09:ABSOLUTE fetch pmem(asr)
    "001100100000000100000000",  --             asr <= pmem(asr)
    
    "001100000000000000000000",  -- 0B:DIRECT   fetch pmem(asr)
    "001100100000000000000000",  --             asr <= pmem(asr)
    "001100000000000000000000",  --             fetch pmem(asr)
    "001100100000000100000000",  --             asr <= pmem(asr)

    "001100000000000000000000",  -- 0F:INDIRECT fetch pmem(asr)
    "001100100000000000000000",  --             asr <= pmem(asr)
    "001100000000000000000000",  --             fetch pmem(asr)
    "001100100000000000000000",  --             asr <= pmem(asr)
    "001100000000000000000000",  --             fetch pmem(asr)
    "001100100000000100000000",  --             asr <= pmem(asr)

    "000000000000000100000000",  -- 15:OP       micro_pc <= OP
    
    "001011000000001100000000",  -- 16:mv       pmem(res) <= asr

    "110000000000000000000000",  -- 17:add      fetch pmem(res)
    "110001000000000000000000",  --             alu_res <= pmem(res)
    "001000000001000000000000",  --             alu_res += asr
    "010011000000001100000000",  --             pmem(res) <= alu_res

    "110000000000000000000000",  -- 1B:sub      fetch pmem(res)
    "110001000000000000000000",  --             alu_res <= pmem(res)    
    "001000000010000000000000",  --             alu_res -= asr
    "010011000000001100000000",  --             pmem(res) <= alu_res
    
    "000000000000010100000000",  -- 1F:beq      if z = 0: u_pc <= 0 
    "001000010000001100000000",  --             PC <= asr
    
    "000000000000011100000000",  -- 21:bne      if z = 1: u_pc <= 0
    "001000010000001100000000",  --             PC <= asr
    
    "000000000000100100000000",  -- 23:bn       if n = 0: u_pc <= 0 
    "001000010000001100000000",  --             PC <= asr
          
    "001000000011000000000000",  -- 25:not      alu_res <= not asr
    "010011000000001100000000",  --             pmem(res) <= alu_res

    "110000000000000000000000",  -- 27:and      fetch pmem(res)
    "110001000000000000000000",  --             alu_res <= pmem(res)    
    "001000000100000000000000",  --             alu_res <= alu_res and asr
    "010011000000001100000000",  --             pmem(res) <= alu_res

    "110000000000000000000000",  -- 2B:or       fetch pmem(res)
    "110001000000000000000000",  --             alu_res <= pmem(res)       
    "001000000101000000000000",  --             alu_res <= alu_res or asr
    "010011000000001100000000",  --             pmem(res) <= alu_res

    "110000000000000000000000",  -- 2F:xor      fetch pmem(res)
    "110001000000000000000000",  --             alu_res <= pmem(res)          
    "001000000110000000000000",  --             alu_res = alu_res xor asr
    "010011000000001100000000",  --             pmem(res) <= alu_res
   
    "001000010000001100000000",  -- 33:jmp      PC <= asr
    "001001010000001100000000",  -- 34:res      res <= asr  (load res)

    "110100110000001100000000",  -- 35:ran      pmem(asr) <= rand_nr

    "110000000000000000000000",  -- 36:cmp      fetch pmem(res)  
    "110001000000000000000000",  --             alu_res <= pmem(res)         
    "001000000010001100000000",  --             alu_res <= alu_res - asr

    "000000000000011000000000",  -- 39:bp       if n = 1: u_pc <= 0 
    "001000010000001100000000",  --             PC <= asr


    "000000000000101000000000",  -- 3B:rfi      (return from interrupt)         
    "000000000000001100000000",  --             micro_pc <= 0
    
    "111000000000000000000000",  -- 3D:pcmp     fetch progress
    "111001000000000000000000",  --             alu_res <= progress
    "001000000010001100000000",  --             alu_res <= alu_res - asr

    "111000000000000000000000",  -- 40:pmod     fetch progress
    "111001000000000000000000",  --             alu_res <= progress 
    "110000000111001100000000",  --             alu_res <= alu_res mod pmem(res), u_pc <= 0

    
    "000000000000110000000000",  -- 43:eint     enable interrupts

    "000100100000000000000000",  -- 44:intr     asr <= pc
    "001100000000000000000000",  --             fetch pmem(asr)
    "001100010000010000000001",  --             pc <= pmem(asr), micro_pc <= 1   

    "001011100000000000000000",  -- 47:lprg     progress <= asr
    
    -- NOTE: place all new micro programs above upd, in case update needs to...update
    
    "000000000000000000000001",  -- 48:upd      player_x <= pmem(x_pos)
    "000000000000000000000010",  --             player_y <= pmem(y_pos)
    "000000000000000000000011",  --             height <= pmem(height_pos)
    "000000000000000000000100",  --             gap <= pmem(gap_pos)
    "000000000000000000000101",  --             speed <= pmem(speed_pos)
    "000000000000001100000000",  --             micro_pc <= 0
    
    
    "000000000000000000000000",  --             c
    "000000000000000000000000",  --             c
    "000000000000000000000000",  --             c

    "000000000000000000000000",  -- XX:INS      comment         
    "000000000000000000000000",  --             c    
    
 --   "", --
    others => "000000000000000000000000");

  
  -- ROM (mod) (Includes all 4 mods, need to be updated with correct micro-addresses)
  type mod_rom_t is array (0 to 3) of std_logic_vector(7 downto 0);
  constant mod_rom : mod_rom_t := (x"09", x"0B", x"0F", x"00");

begin  -- Behavioral

  -- fetching micro_instr
  micro_instr <= micro_mem(to_integer(unsigned(micro_pc)));

  
  -- Speed
  speed <= speed_internal;


  -- Update 
  process(clk)
  begin
    if rising_edge(clk) then

      -- Put the information from pmem on the correct signals
      -- (this makes sure vga_motor and pic_mem has the correct information
      -- for drawing on the screen)
      if micro_instr = "000000000000000000000001" then
        player_x <= to_integer(unsigned(pmem(to_integer(unsigned(x_pos)))));
      elsif micro_instr = "000000000000000000000010" then
        player_y <= to_integer(unsigned(pmem(to_integer(unsigned(y_pos)))));
      elsif micro_instr = "000000000000000000000011" then
        height <= to_integer(unsigned(pmem(to_integer(unsigned(height_pos)))));
      elsif micro_instr = "000000000000000000000100" then
        gap <= to_integer(unsigned(pmem(to_integer(unsigned(gap_pos)))));
      elsif micro_instr = "000000000000000000000101" then
        speed_internal <= to_integer(unsigned(pmem(to_integer(unsigned(speed_pos)))));        
      end if;
    end if;
  end process;
  
  -- pc
  process(clk)
  begin
    if rising_edge(clk) then
      -- pc to bus
      if FROM_BUS = "0001" then
        pc <= data_bus;

      -- pc++
      elsif P_BIT = '1' then
        pc <= std_logic_vector(unsigned(pc) + 1);
       
      -- Handle interrupts
      elsif SEQ = "1111" and intr_enable = '1' then        

        -- Store important information to be returned after the interrupt
        intr_pc <= pc;
        intr_res <= res;
        intr_alu_res <= alu_res;
        intr_z <= z_flag;
        intr_n <= n_flag;
        intr_o <= o_flag;
        intr_c <= c_flag;

 
        -- Set pc to the correct interrupt vector and disables interrupts
        -- (interrupts are enabled after the specific interrupt code has been run)
        if reset_alert = '1' then
          intr_enable <= '0';
          reset_alert <= '0';
          pc <= RESET_INTERRUPT_VECTOR;
        elsif collision_alert = '1' then
          intr_enable <= '0';
          collision_alert <= '0';
          pc <= COLLISION_INTERRUPT_VECTOR;
        elsif terrain_alert = '1'  then
          intr_enable <= '0';
          terrain_alert <= '0';
          pc <= TERRAIN_CHANGE_INTERRUPT_VECTOR;
        end if;

      -- Return from interrupt: enable interrupts and restore pc
      elsif SEQ = "1010" then
        intr_enable <= '1';
        pc <= intr_pc;

      -- Enable interrupts
      elsif SEQ = "1100" then
        intr_enable <= '1';
      end if;

      -- Check if the terrain needs to update
      if terrain_change = '1' and terrain_prev = '0' then
          terrain_alert <= '1';
      end if;

      -- Check if there has been a collision
      if collision = '1' and collision_prev = '0' then
          collision_alert <= '1';
      end if;

      -- Check if the reset button has been pressed
      if reset = '1' and reset_prev = '0' then
          reset_alert <= '1';
      end if;
      
      terrain_prev <= terrain_change;
      collision_prev <= collision;
      reset_prev <= reset;
    end if;
  end process;

  -- asr
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "0010" then
        asr <= data_bus;
      end if;
    end if;
  end process;

  -- pmem
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "0011" then
        pmem(to_integer(unsigned(asr))) <= data_bus;
      elsif FROM_BUS = "1100" then
        pmem(to_integer(unsigned(res))) <= data_bus;
      elsif TO_BUS = "0011" then
        pmem_asr <= pmem(to_integer(unsigned(asr)));
      elsif TO_BUS = "1100" then
        pmem_res <= pmem(to_integer(unsigned(res)));

      -- Write to memory if the player position needs to update
      elsif player_upd_alert = '1' then
        player_upd_alert <= '0';
        pmem(to_integer(unsigned(player_upd))) <= ONE;

      -- Write to memory if the spacebar has been released
      elsif release_alert = '1' then
        release_alert <= '0';
        pmem(to_integer(unsigned(release_pos))) <= ONE;

      -- Write to memory if the spacebar has been pressed
      elsif press_alert = '1' then
        press_alert <= '0';
        pmem(to_integer(unsigned(press_pos))) <= ONE;
        
      end if;
     
      -- Creates a delay (based on speed) which decides when the player position
      -- should update
      if player_upd_counter >= player_speed then
        player_upd_alert <= '1';
        player_upd_counter <= 0;
      else
        player_upd_counter <= player_upd_counter + 1;
      end if;
      
      -- Check if the spacebar has been pressed
      if input = '1' and input_prev = '0' then
        press_alert <= '1';
      end if;

      -- Check if the spacebar has been released
      if input = '0' and input_prev = '1' then
        release_alert <= '1';
      end if;
      
      input_prev <= input;
 
    end if;
  end process;

  -- Makes sure that the player speed gets faster as speed increases,
  -- but not as fast as the terrain speed increases
  player_speed <= (speed_internal*1000) + ((1000-speed_internal)*900);


  -- progress
  process(clk)
  begin
    if rising_edge(clk) then
      -- bus to progress, reset progress_counter
      if FROM_BUS = "1110" then
        progress <= unsigned(data_bus);
        progress_counter <= 0;

      -- Increases progress every second (on a 100MHz clock)
      elsif progress_counter = PROGRESS_LATENCY then
        progress <= progress + 1;
        progress_counter <= 0;
      else
        progress_counter <= progress_counter + 1;
      end if;
    end if;
  end process;


  -- score
  process(clk)
  begin
    if rising_edge(clk) then
      -- Reset score if there is a collision or if the game is reset
      if reset = '1' or collision = '1' then
        score <= 0;
        score_counter <= 0;

      -- keep counting score up every 1/10th of a second
      elsif score_counter = SCORE_LATENCY then
        score <= score + 1;
        score_counter <= 0;
      else
        score_counter <= score_counter + 1;
      end if;
    end if;
  end process;
  
  
  -- res
  process(clk)
  begin
    if rising_edge(clk) then
      -- from bus to res
      if FROM_BUS = "0101" then
        res <= data_bus;

      -- Return from interrupt: restore res
      elsif SEQ = "1010" then
        res <= intr_res;
        
      end if;
    end if;
  end process;

  -- from bus to ir
  process(clk)
  begin
    if rising_edge(clk) then

      -- from bus to ir(31->16)
      if FROM_BUS = "0110" then
        ir(31 downto 16) <= data_bus;

      -- from bus to ir(15->0)  
      elsif FROM_BUS = "0111" then
        ir(15 downto 0) <= data_bus;
      end if;
      
    end if;
  end process;

  -- from bus to reg1
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1000" then
        reg1 <= data_bus;
      end if;
    end if;
  end process;

  -- from bus to reg2
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1001" then
        reg2 <= data_bus;
      end if;
    end if;
  end process;

  -- from bus to reg3
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1010" then
        reg3 <= data_bus;
      end if;
    end if;
  end process;

  -- from bus to reg4
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1011" then
        reg4 <= data_bus;
      end if;
    end if;
  end process;

  
  -- Moving data TO the bus
  with TO_BUS select
    data_bus <= pc when "0001",    
                asr when "0010",
                pmem_asr when "0011",
                alu_res when "0100",
                res when "0101",
                ir(31 downto 16) when "0110",
                ir(15 downto 0) when "0111",
                reg1 when "1000",
                reg2 when "1001",
                reg3 when "1010",
                reg4 when "1011",       
                pmem_res when "1100",
                ran_nr(31 downto 16) when "1101",
                std_logic_vector(progress) when "1110",

                data_bus when others;

  
  -- micro_pc
  process(clk)
  begin
    if rising_edge(clk) then
      if SEQ = "0000"  then    -- micro_pc += 1
        micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        
      elsif SEQ = "0001"  then -- micro_pc = op
        micro_pc <= ir(31 downto 24);
        
      elsif SEQ = "0010"  then --micro_pc = mod
        micro_pc <= mod_rom(to_integer(unsigned(ir(23 downto 22))));          
         
      elsif SEQ = "0011"  then --micro_pc = 0
        micro_pc <= "00000000";

      elsif SEQ = "0100"  then -- jmp
        micro_pc <= MICRO_ADR;
        
      elsif SEQ = "0101"  then --jmp if Z = 1     --BEQ--
        if z_flag = '0' then
          micro_pc <= MICRO_ADR;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        end if;

      elsif SEQ = "0110"  then --jmp if N = 0     --BP--
        if n_flag = '1' then
          micro_pc <= MICRO_ADR;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        end if;

      elsif SEQ = "0111"  then --jmp if Z = 0      --BNE--
        if z_flag = '1' then
          micro_pc <= MICRO_ADR;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        end if;

      elsif SEQ = "1000" then  --check for 16 bit inst
        if FETCH_NEXT = '0' then
          micro_pc <= MICRO_ADR;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        end if;

      elsif SEQ = "1001" then --jmp if N = 1      --BN--
        if n_flag = '0' then
          micro_pc <= MICRO_ADR;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        end if;

      -- Jump to the interrupt micro program if there's an interrupt and
      -- interrupts are enabled
      elsif SEQ = "1111" then
        if intr_enable = '1' then
          if (reset_alert = '1') or (collision_alert = '1') or (terrain_alert = '1')  then
            micro_pc <= MICRO_ADR;
          else
            micro_pc <= std_logic_vector(unsigned(micro_pc) + 1); 
          end if;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1); 
        end if;
      -- Fetch new instruction when returning from interrupt
      elsif SEQ = "1100" then
        micro_pc <= MICRO_ADR;          -- MICRO_ADR will be 0
        
      elsif SEQ = "1010" then
        micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        
      else
        micro_pc <= micro_pc;
      end if;
    end if;
end process;



  -- alu combinatorics
  alu_add <= std_logic_vector(signed(alu_res(15) & alu_res) + signed(data_bus(15) & data_bus));
  alu_sub <= std_logic_vector(signed(alu_res(15) & alu_res) - signed(data_bus(15) & data_bus));
  alu_not <= not data_bus;
  alu_and <= alu_res and data_bus;
  alu_or <= alu_res or data_bus;
  alu_xor <= alu_res xor data_bus;

  alu_int <= to_integer(unsigned(alu_res));
  alu_mod <= std_logic_vector(to_unsigned(alu_int mod 4, 16));

  
  -- alu_res
  process(clk)
  begin
    if rising_edge(clk) then
      case ALU_OP is
        when "001" =>                   -- ADD
          alu_res <= alu_add(15 downto 0);
        
          if alu_add = "00000000000000000" then  -- z_flag
            z_flag <= '1';
          else
            z_flag <= '0';
          end if;
          
          n_flag <= alu_add(15);                -- n_flag
          c_flag <= alu_add(16);                -- c_flag
          if alu_res(15) = data_bus(15) then    -- o_flag
            if alu_res(15) = '0' and data_bus(15) = '0' and alu_add(15) = '1' then
              o_flag <= '1';
            elsif alu_res(15) = '1' and data_bus(15) = '1' and alu_add(15) = '0' then
              o_flag <= '1';
              else
              o_flag <= '0';
            end if;
          else
            o_flag <= '0';
          end if;

          
        when "010" =>                   -- SUB
          alu_res <= alu_sub(15 downto 0);

          if alu_sub = "00000000000000000" then  -- z_flag
            z_flag <= '1';
          else
            z_flag <= '0';
          end if;
          
          n_flag <= alu_sub(15);                -- n_flag
          c_flag <= '0';                        -- c_flag (no meaning when subtracting)
          
          if alu_res(15) /= data_bus(15) then   -- o_flag
            if (alu_res(15) = '0' and data_bus(15) = '1' and alu_sub(15) = '1') then
              o_flag <= '1';
            elsif alu_res(15) = '1' and data_bus(15) = '0' and alu_sub(15) = '0' then
              o_flag <= '1';
            else
              o_flag <= '0';
            end if;
          else
            o_flag <= '0';
          end if;

        when "011" =>
          alu_res <= alu_not;                                               --NOT
          if alu_not = "0000000000000000" then  -- z_flag
            z_flag <= '1';
          else
            z_flag <= '0';
          end if;

        when "100" =>
          alu_res <= alu_and;                                               --AND
          if alu_and = "0000000000000000" then  -- z_flag
            z_flag <= '1';
          else
            z_flag <= '0';
          end if;

          n_flag <= alu_and(15);
          o_flag <= '0';
          c_flag <= '0';          
          
        when "101" =>
          alu_res <= alu_or;                                                --OR
          if alu_or = "0000000000000000" then  -- z_flag
            z_flag <= '1';
          else
            z_flag <= '0';
          end if;

          n_flag <= alu_or(15);
          o_flag <= '0';
          c_flag <= '0';
        when "110" =>
          alu_res <= alu_xor;                                               --XOR
          if alu_xor = "0000000000000000" then  -- z_flag
            z_flag <= '1';
          else
            z_flag <= '0';
          end if;

          n_flag <= alu_xor(15);
          o_flag <= '0';
          c_flag <= '0';
        when "111" => 
          alu_res <= alu_mod;                                               --MOD
          if alu_mod = "0000000000000000" then
            z_flag <= '1';
          else
            z_flag <= '0';
          end if;
          n_flag <= '0';
          o_flag <= '0';
          c_flag <= '0';
         
        when others =>
          if FROM_BUS = "0100" then
            alu_res <= data_bus;

          -- Return from interrupt: restore all flags and alu_res
          elsif SEQ = "1010" then
            alu_res <= intr_alu_res;
            z_flag <= intr_z;
            n_flag <= intr_n;
            o_flag <= intr_o;
            c_flag <= intr_c;
        
          else
            alu_res <= alu_res;
          end if;
          n_flag <= n_flag;
          o_flag <= o_flag;
          c_flag <= c_flag;
          z_flag <= z_flag;
      end case;
    end if;
  end process;


  
  --ran_gen
  ran_bit <= new_ran(31) xor new_ran(29) xor new_ran(25) xor new_ran(24);
  ran_nr <= new_ran;

  process(clk)
  begin
    if rising_edge(clk) then
      new_ran(31 downto 1) <= new_ran(30 downto 0);
      new_ran(0) <= ran_bit; 
    end if;
  end process;
  
end Behavioral;
