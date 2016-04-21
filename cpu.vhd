--CPU

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type



entity CPU is
  port ( clk : in std_logic;
         collision : in std_logic
         reset : in std_logic;
         input : in std_logic
    );
    
 
end CPU;


architecture Behavioral of CPU is

  -- Component ALU goes here
  component ALU
    port ( clk : in std_logic;
           OP : in std_logic_vector(2 downto 0);
           input : in signed(15 downto 0);
           result : out std_logic_vector(15 downto 0));
  end component;

  -- Signals
  signal alu_op : std_logic_vector(2 downto 0);
  signal data_bus : std_logic_vector(15 downto 0);
  signal pc : std_logic_vector(15 downto 0);
  signal asr : std_logic_vector(15 downto 0);
  signal alu_input : signed(15 downto 0);
  signal alu_res : std_logic_vector(15 downto 0);
  signal res : std_logic_vector(15 downto 0);
  signal ir : std_logic_vector(31 downto 0);

  signal reg1 : std_logic_vector(15 downto 0);
  signal reg2 : std_logic_vector(15 downto 0);
  signal reg3 : std_logic_vector(15 downto 0);
  signal reg4 : std_logic_vector(15 downto 0);

  signal micro_instr : std_logic_vector(7 downto 0);
  signal micro_pc : unsigned(7 downto 0);

  
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

  ar_log_unit : ALU port map(clk => clk,
                     OP => alu_op,
                     input => alu_input,
                     result => alu_res);
                     
  -- Pushing data TO the bus
  with micro_instr(7 downto 4) select
    data_bus <= pc when "0001",    
                asr when "0010",
                alu_res when "0101",
                res when "0110",
                ir(31 downto 16) when "0111",
                reg1 when "1000",
                reg2 when "1001",
                reg3 when "1010",
                reg4 when "1011",
                data_bus when others;

  -- Pulling data FROM the bus
  process(clk)
  begin
    if rising_edge(clk) then
      if micro_instr(3 downto 0) = "0001" then
        pc <= data_bus;
      elsif micro_instr(3 downto 0) = "0010" then
        asr <= data_bus;
      elsif micro_instr(3 downto 0) = "0101" then
        alu_res <= data_bus;
      elsif micro_instr(3 downto 0) = "0110" then
        res <= data_bus;
      elsif micro_instr(3 downto 0) = "0111" then
        ir(31 downto 16) <= data_bus;
      elsif micro_instr(3 downto 0) = "1000" then
        reg1 <= data_bus;
      elsif micro_instr(3 downto 0) = "1001" then
        reg2 <= data_bus;
      elsif micro_instr(3 downto 0) = "1010" then
        reg3 <= data_bus;
      elsif micro_instr(3 downto 0) = "1011" then
        reg4 <= data_bus;
      end if;    
    end if;
  end process;


  -- micro_pc
  process(clk)
  begin
    if rising_edge(clk) then
      if micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0000"  then  -- micro_pc += 1
        micro_pc <= micro_pc + 1;
        
      elsif micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0001"  then --micro_pc = op
        micro_pc <= unsigned(op_rom(to_integer(unsigned(ir(31 downto 26)))));
        
      elsif micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0010"  then --micro_pc = mod
         micro_pc <= unsigned(mod_rom(to_integer(unsigned(ir(31 downto 26)))));
         
      elsif micro_mem(to_integer(unsigned(micro_pc)))(11 downto 8) = "0011"  then --micro_pc = 0
        micro_pc <= "00000000";
      else
        micro_pc <= micro_pc;
      end if;
    end if;
  end process;
  
end Behavioral;
