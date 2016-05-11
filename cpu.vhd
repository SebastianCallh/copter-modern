--CPU

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type



entity CPU is
    port ( clk                 : in std_logic;                          -- systen clock
           collision           : in std_logic;
           reset               : in std_logic;
           player_x            : out integer;
           player_y            : out integer;
           input               : in std_logic;
           new_column          : in std_logic);   
    
 
end CPU;


architecture Behavioral of CPU is

  -- Signals
  signal data_bus : std_logic_vector(15 downto 0);
  signal pc : std_logic_vector(15 downto 0) := "0000000000000000";
  signal asr : std_logic_vector(15 downto 0);
  signal alu_input : signed(15 downto 0);
  signal alu_res : std_logic_vector(15 downto 0);
  signal res : std_logic_vector(15 downto 0);
  signal ir : std_logic_vector(31 downto 0);
  signal pmem_asr : std_logic_vector(15 downto 0);
  signal pmem_res : std_logic_vector(15 downto 0);

  -- Registers
  signal reg1 : std_logic_vector(15 downto 0);
  signal reg2 : std_logic_vector(15 downto 0);
  signal reg3 : std_logic_vector(15 downto 0);
  signal reg4 : std_logic_vector(15 downto 0);


  -- Micro
  signal micro_instr : std_logic_vector(23 downto 0);
  signal micro_pc : std_logic_vector(7 downto 0) := "00000000";


   -- ALU signals
  signal alu_add : std_logic_vector(16 downto 0);
  signal alu_sub : std_logic_vector(16 downto 0);
  signal alu_not : std_logic_vector(15 downto 0);
  signal alu_and : std_logic_vector(15 downto 0);
  signal alu_or : std_logic_vector(15 downto 0);
  signal alu_xor : std_logic_vector(15 downto 0);

  --ran_gen signals
  signal ran_nr : std_logic_vector(31 downto 0) := (others => '0');
  signal ran_bit : std_logic;
  -- init value for new_ran is seed
  signal new_ran : std_logic_vector(31 downto 0) := "11110000111100001111000011110000";
                                                                      
  
  -- Flags
  signal n_flag : std_logic;
  signal z_flag : std_logic;
  signal o_flag : std_logic;
  signal c_flag : std_logic;


  -- Constants (Variables)
  signal x_pos : std_logic_vector(15 downto 0) := "0000000000000010";
  signal y_pos : std_logic_vector(15 downto 0) := "0000000000000011";
  
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
  constant RESET_INTERRUPT_VECTOR : std_logic_vector(15 downto 0) := x"DC";  --220
  constant COLLISION_INTERRUPT_VECTOR : std_logic_vector(15 downto 0) := x"E6"; --230
  constant INPUT_INTERRUPT_VECTOR : std_logic_vector(15 downto 0) := x"F0";  --240
  constant NEW_COLUMN_INTERUPT_VECTOR : std_logic_vector(7 downto 0) := x"FA";  --250

  -- PMEM (Max is 65535 for 16 bit addresses)
  type ram_t is array (0 to 4096) of std_logic_vector(15 downto 0);
  signal pmem : ram_t := (
    "0001110101100000",                 -- jmp absolute test
    "0000000000001011",
    "0000000010000000",                 
    "0000000010000000",
    "0000000000000000",
    "0000000000000000",
    "0000000000000000",
    "0000000000000000",
    "0000000000000000",
    "0000000011111111",                 -- lr direct test
    "0000000000001011",
    "0000000000001000",

    others => "0000000000000000");

  -- micro-MEM (Max is 255 for 8 bit addresses)
  type micro_mem_t is array (0 to 255) of std_logic_vector(23 downto 0);
  signal micro_mem : micro_mem_t := (
    "000100100000111100000000",  -- check for interrupts, ASR <= PC
    "001101100000000000000000",  -- fetch instruction (only 16 bits)
                                 -- and check for 32 bit instruction
    "000000001000100000000101",  -- if 16 bit fetch next 8
    "000100101000000000000000",  -- asr <= pc, pc++
    "001101110000000000000000",  -- ir(15 downto 0) <= pmem(asr)
    "000000000000001000000000",  -- 05:check adress mod
    "001100100000000100000000",  -- 06:absolute asr <= pmem(asr)
    "001100100000000000000000",  -- 07:direct   asr <= pmem(asr)
    "001100100000000100000000",  --             asr <= pmem(asr)
    "001011000000001100000000",  -- 09:mv       pmem(res) <= asr
    "001100000001000000000000",  -- 0A:add      alu_res += pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "001100000010000000000000",  -- 0C:sub      alu_res -= pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "000000000000011100000000",  -- 0E:beq      if z = 0: u_pc <= 0 
    "001000010000001100000000",  --             PC <= asr
    "000000000000010100000000",  -- 10:bne      if z = 1: u_pc <= 0
    "001000010000001100000000",  --             PC <= asr
    "000000000000011000000000",  -- 12:bn       if n = 0: u_pc <= 0 
    "001000010000001100000000",  --             PC <= asr
    "001100000011000000000000",  -- 14:not      alu_res = not pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "001100000100000000000000",  -- 16:and      alu_res = alu_res and pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "001100000101000000000000",  -- 18:or       alu_res = alu_res or pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "001100000110000000000000",  -- 1A:xor      alu_res = alu_res xor pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "001000010000001100000000",  -- 1C:jmp      PC <= asr
    "001001010000001100000000",  -- 1D:lr       res <= asr  (load res)
    "001001000000001100000000",  -- 1E:lar      alu_res <= asr (load alu_res)
    "",
    "",
 --   "", --
    others => "000000000000000000000000");

  
  -- ROM (mod) (Includes all 4 mods, need to be updated with correct micro-addresses)
  type mod_rom_t is array (0 to 3) of std_logic_vector(7 downto 0);
  constant mod_rom : mod_rom_t := (x"06", x"07", x"00", x"00");

begin  -- Behavioral

  -- fetching micro_instr
  micro_instr <= micro_mem(to_integer(unsigned(micro_pc)));


  
  -- pc
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "0001" then
        pc <= data_bus;
      elsif P_BIT = '1' then
        pc <= std_logic_vector(unsigned(pc) + 1);
        
      --interrupts 
      elsif SEQ = "1111" then
        if reset = '1' then
          pc <= RESET_INTERRUPT_VECTOR;
        elsif collision = '1' then 
          pc <= COLLISION_INTERRUPT_VECTOR;
        elsif input = '1' then 
          pc <= INPUT_INTERRUPT_VECTOR;
        end if;
        
      end if;
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
      elsif SEQ = "1001" then
        player_x <= to_integer(unsigned(pmem(to_integer(unsigned(x_pos)))));
      elsif SEQ = "1010" then
        player_y <= to_integer(unsigned(pmem(to_integer(unsigned(y_pos)))));
      end if;
    end if;
  end process;

  -- res
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "0101" then
        res <= data_bus;
      end if;
    end if;
  end process;

  -- ir
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "0110" then
        ir(31 downto 16) <= data_bus;
      elsif FROM_BUS = "0111" then
        ir(15 downto 0) <= data_bus;
      end if;
      
    end if;
  end process;

  -- reg1
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1000" then
        reg1 <= data_bus;
      end if;
    end if;
  end process;

  -- reg2
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1001" then
        reg2 <= data_bus;
      end if;
    end if;
  end process;

  -- reg3
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1010" then
        reg3 <= data_bus;
      end if;
    end if;
  end process;

  -- reg4
  process(clk)
  begin
    if rising_edge(clk) then
      if FROM_BUS = "1011" then
        reg4 <= data_bus;
      end if;
    end if;
  end process;

  
  -- Pushing data TO the bus
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
        
      elsif SEQ = "0101"  then --jmp if Z = 1
        if z_flag = '1' then
          micro_pc <= MICRO_ADR;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        end if;

      elsif SEQ = "0110"  then --jmp if N = 0
        if n_flag = '0' then
          micro_pc <= MICRO_ADR;
        else
          micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        end if;

      elsif SEQ = "0111"  then --jmp if Z = 0
        if z_flag = '0' then
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
          alu_res <= alu_res;                                               --||UNUSED||
          n_flag <= '0';
          o_flag <= '0';
          c_flag <= '0';
          z_flag <= '0';
         
        when others =>
          if FROM_BUS = "0100" then
            alu_res <= data_bus;
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
