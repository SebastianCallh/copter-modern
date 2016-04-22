--CPU

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type



entity CPU is
  port ( clk : in std_logic;
         collision : in std_logic;
         reset : in std_logic;
         input : in std_logic
    );
    
 
end CPU;


architecture Behavioral of CPU is

  -- Signals
  signal data_bus : std_logic_vector(15 downto 0);
  signal pc : std_logic_vector(15 downto 0);
  signal asr : std_logic_vector(15 downto 0);
  signal alu_input : signed(15 downto 0);
  signal alu_res : std_logic_vector(15 downto 0);
  signal res : std_logic_vector(15 downto 0);
  signal ir : std_logic_vector(31 downto 0);

  -- Registers
  signal reg1 : std_logic_vector(15 downto 0);
  signal reg2 : std_logic_vector(15 downto 0);
  signal reg3 : std_logic_vector(15 downto 0);
  signal reg4 : std_logic_vector(15 downto 0);

  -- Micro
  signal micro_instr : std_logic_vector(23 downto 0);
  signal micro_pc : std_logic_vector(7 downto 0);


  -- Flags
  signal n_flag : std_logic;
  signal z_flag : std_logic;
  signal o_flag : std_logic;
  signal c_flag : std_logic;


  -- ALU help signal
  signal alu_tmp : std_logic_vector(16 downto 0);
  
  
  -- PMEM (Max is 65535 for 16 bit addresses)
  type ram_t is array (0 to 4096) of std_logic_vector(15 downto 0);
  signal pmem : ram_t := (others => "0000000000000000");

  -- micro-MEM (Max is 255 for 8 bit addresses)
  type micro_mem_t is array (0 to 255) of std_logic_vector(23 downto 0);
  signal micro_mem : micro_mem_t := (others => "000000000000000000000000");

  -- ROM (mod) (Includes all 4 mods, need to be updated with correct micro-addresses)
  type mod_rom_t is array (3 downto 0) of std_logic_vector(7 downto 0);
  constant mod_rom : mod_rom_t := (x"FF", x"FF", x"00", x"00");
    
  -- ROM (op-code)(Number of unique instructions, size of micro-memory adress)
  -- Will need to be updated with correct amount of instructions and micro-addresses)
  type op_rom_t is array (5 downto 0) of std_logic_vector(7 downto 0);
  constant op_rom : op_rom_t := (x"FF",
                                 x"FF",
                                 x"FF",
                                 x"00",
                                 x"00",
                                 x"00");

  
begin  -- Behavioral
  
  -- Pushing data TO the bus
  with micro_instr(23 downto 20) select
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

  -- Pulling data FROM the bus
  process(clk)
  begin
    if rising_edge(clk) then 
      case micro_instr(19 downto 16) is
        when "0001" =>
          pc <= data_bus;
        when "0010" =>
          asr <= data_bus;
        when "0011" =>
          pmem(to_integer(unsigned(asr))) <= data_bus;
        when "0100" =>
          alu_res <= data_bus;
        when "0101" =>
          res <= data_bus;
        when "0110" =>
          ir(31 downto 16) <= data_bus;
        when "0111" =>
          ir(15 downto 0) <= data_bus;
        when "1000" =>
          reg1 <= data_bus;
        when "1001" =>
          reg2 <= data_bus;
        when "1010" =>
          reg3 <= data_bus;
        when "1011" =>
          reg4 <= data_bus;
        when others => null;
      end case;
    end if;
  end process;


  -- micro_pc
  process(clk)
  begin
    if rising_edge(clk) then
      if micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0000"  then  -- micro_pc += 1
        micro_pc <= std_logic_vector(unsigned(micro_pc) + 1);
        
      elsif micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0001"  then --micro_pc = op
        micro_pc <= op_rom(to_integer(unsigned(ir(31 downto 26))));
        
      elsif micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0010"  then --micro_pc = mod
         micro_pc <= mod_rom(to_integer(unsigned(ir(31 downto 26))));
         
      elsif micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0011"  then --micro_pc = 0
        micro_pc <= "00000000";
      else
        micro_pc <= micro_pc;
      end if;
    end if;
  end process;


  -- ALU
  process(clk)
  begin
    if rising_edge(clk) then
      case micro_instr(14 downto 12) is
        when "001" =>
          alu_tmp <= std_logic_vector(signed(alu_res) + signed(data_bus));
          
                     

          alu_res <= std_logic_vector(signed(alu_res) + signed(data_bus));  --ADD
        when "010" =>
          alu_res <= std_logic_vector(signed(alu_res) - signed(data_bus));  --SUB
        when "011" =>
          alu_res <= not data_bus;                                          --NOT
        when "100" =>
          alu_res <= alu_res and data_bus;                                  --AND
        when "101" =>
          alu_res <= alu_res or data_bus;                                   --OR
        when "110" =>
          alu_res <= alu_res xor data_bus;                                  --XOR
        when "111" =>
          alu_res <= alu_res;                                               --||UNUSED||
        when others => null;
      end case;
    end if;
  end process;
  
end Behavioral;
