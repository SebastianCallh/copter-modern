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
           input               : in std_logic);   
    
 
end CPU;


architecture Behavioral of CPU is

  -- Signals
  signal data_bus : std_logic_vector(15 downto 0);
  signal pc : std_logic_vector(15 downto 0);
  signal asr : std_logic_vector(15 downto 0) := "0000000000000000";
  signal alu_input : signed(15 downto 0);
  signal alu_res : std_logic_vector(15 downto 0) := "0000000000000000";
  signal res : std_logic_vector(15 downto 0) := "0000000000000001";
  signal ir : std_logic_vector(31 downto 0);

  -- Registers
  signal reg1 : std_logic_vector(15 downto 0) := "0000010000000000";
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
  
  -- Flags
  signal n_flag : std_logic;
  signal z_flag : std_logic;
  signal o_flag : std_logic;
  signal c_flag : std_logic;


  -- Constants (Variables)
  signal X_POS : std_logic_vector(15 downto 0) := "0000000000000000";
  signal Y_POS : std_logic_vector(15 downto 0) := "0000000000000001";
  
  -- Alias
  alias TO_BUS : std_logic_vector(3 downto 0) is micro_instr(23 downto 20);     -- to bus
  alias FROM_BUS : std_logic_vector(3 downto 0) is micro_instr(19 downto 16);   -- from bus
  alias P_BIT : std_logic is micro_instr(15);                                   -- p bit
  alias ALU_OP : std_logic_vector(2 downto 0) is micro_instr(14 downto 12);     -- alu_op
  alias SEQ : std_logic_vector(3 downto 0) is micro_instr(11 downto 8);         -- seq
  alias MICRO_ADR : std_logic_vector(7 downto 0) is micro_instr(7 downto 0);    -- micro address

  alias FETCH_NEXT : std_logic is ir(23);
  alias OP_CODE : std_logic_vector(7 downto 0) is ir(31 downto 24);
    
  -- Interrupt vectors
  constant RESET_INTERRUPT_VECTOR : std_logic_vector(7 downto 0) := x"DC";  --220
  constant COLLISION_INTERRUPT_VECTOR : std_logic_vector(7 downto 0) := x"E6"; --230
  constant INPUT_INTERRUPT_VECTOR : std_logic_vector(7 downto 0) := x"F0";  --240

  -- PMEM (Max is 65535 for 16 bit addresses)
  type ram_t is array (0 to 4096) of std_logic_vector(15 downto 0);
  signal pmem : ram_t := ("0000000001000000",
                          "0000000000000010",
                          others => "0000000000000000");

  -- micro-MEM (Max is 255 for 8 bit addresses)
  type micro_mem_t is array (0 to 255) of std_logic_vector(23 downto 0);
  signal micro_mem : micro_mem_t := (
    "000100100000111100000000",  -- check for interrupts, ASR <= PC
    "001101100000100000000000",  -- fetch instruction (only 16 bits)
                                 -- and check for 32 bit instruction
    "000000001000100000000101",  -- if 16 bit fetch next 8
    "000100101000000000000000",
    "001101110000000000000000",
    "000000000000001000000000",  -- check adress mod
    "011100100000000100000000",  -- 05:absolute  asr <= pmem(asr)
    "011000100000000000000000",  -- 06:indirect  asr <= pmem(asr)
    "001100100000000100000000",  --             asr <= pmem(asr)
    "001111000000001100000000",  -- 08:mv        pmem(res) <= pmem(asr)
    "001100000001000000000000",  -- 09:add       alu_res += pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "001100000010000000000000",  -- 0B:sub      alu_res -= pmem(asr)
    "010011000000001100000000",  --             pmem(res) <= alu_res
    "000000000000011100000000",  -- 0D:beq      if z = 0: u_pc <= 0 
    "001000010000001100000000",  --             PC <= asr
    "000000000000010100000000",  -- 0F:bne      if z = 1: u_pc <= 0
    "001000010000001100000000",  --             PC <= asr
    "000000000000011000000000",  -- 11:bn       if n = 0: u_pc <= 0 
    "001000010000001100000000",  --             PC <= asr
    others => "000000000000000000000000");

  
  -- ROM (mod) (Includes all 4 mods, need to be updated with correct micro-addresses)
  type mod_rom_t is array (3 downto 0) of std_logic_vector(7 downto 0);
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
      end if;

      if P_BIT = '1' then
        pc <= std_logic_vector(unsigned(pc) + 1);
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
      end if;
      if FROM_BUS = "1100" then
       pmem(to_integer(unsigned(res))) <= data_bus;
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
                pmem(to_integer(unsigned(asr))) when "0011",
                alu_res when "0100",
                res when "0101",
                ir(31 downto 16) when "0110",
                ir(15 downto 0) when "0111",
                reg1 when "1000",
                reg2 when "1001",
                reg3 when "1010",
                reg4 when "1011",
                data_bus when others;


  
  -- micro_pc
  process(clk)
  begin
    if rising_edge(clk) then
      if SEQ = "0000"  then    -- micro_pc += 1
        micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        
      elsif SEQ = "0001"  then -- micro_pc = op
        micro_pc <= ir(31 downto 26);
        
      elsif SEQ = "0010"  then --micro_pc = mod
         micro_pc <= mod_rom(to_integer(unsigned(ir(25 downto 24))));
         
      elsif SEQ = "0011"  then --micro_pc = 0
        micro_pc <= "00000000";

      elsif SEQ = "0100"  then --micro_pc = MICRO_ADR
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
        end if;

      --interrupts 
      elsif SEQ = "1111" then
        if reset = '1' then
          micro_pc <= RESET_INTERRUPT_VECTOR;
        end if;
        if collision = '1' then 
          micro_pc <= COLLISION_INTERRUPT_VECTOR;
        end if;
        if input = '1' then 
          micro_pc <= INPUT_INTERRUPT_VECTOR;
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
          n_flag <= '0';
          o_flag <= '0';
          c_flag <= '0';
          z_flag <= '0';
      end case;



    end if;
  end process;
  
end Behavioral;
