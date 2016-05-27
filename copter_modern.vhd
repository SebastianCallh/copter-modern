--------------------------------------------------------------------------------
-- VGA lab
-- Anders Nilsson
-- 16-dec-2015
-- Version 1.0


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity copter_modern is
  port ( clk	                : in std_logic;                         -- system clock
	 rst                    : in std_logic;                         -- reset
         seg                    : out std_logic_vector(7 downto 0);     --7-segment display
         an                     : out std_logic_vector(3 downto 0);
	 Hsync	                : out std_logic;                        -- horizontal sync
	 Vsync	                : out std_logic;                        -- vertical sync
	 vgaRed	                : out std_logic_vector(2 downto 0);     -- VGA red
	 vgaGreen               : out std_logic_vector(2 downto 0);     -- VGA green
	 vgaBlue	        : out std_logic_vector(2 downto 1);     -- VGA blue
	 PS2KeyboardCLK	        : in std_logic;                         -- PS2 clock
	 PS2KeyboardData        : in std_logic;                         -- PS2 data
         keypress               : out std_logic);                       -- input flag

end copter_modern;


-- architecture
architecture Behavioral of copter_modern is

  -- PS2 keyboard encoder component
  component KBD_ENC
    port ( clk		        : in std_logic;				-- system clock
	   rst		        : in std_logic;				-- reset signal
	   PS2KeyboardCLK       : in std_logic;				-- PS2 clock
	   PS2KeyboardData      : in std_logic;				-- PS2 data
           input                : out std_logic);	                
  end component;
	
  -- VGA motor component
  component VGA_MOTOR
    port ( clk			: in std_logic;                         -- system clock
           rst			: in std_logic;                         -- reset
           vgaRed		: out std_logic_vector(2 downto 0);     -- VGA red
           vgaGreen	        : out std_logic_vector(2 downto 0);     -- VGA green
           vgaBlue		: out std_logic_vector(2 downto 1);     -- VGA blue
           Hsync		: out std_logic;                        -- horizontal sync
           Vsync		: out std_logic;                        -- vertical sync
           player_x             : in integer;
           player_y             : in integer;
           collision            : out std_logic;
           new_column           : out std_logic;
           gap                  : in integer;
           height               : in integer;
           terrain_change       : out std_logic;
           speed                : in integer);    
  end component;


  -- CPU
  component CPU
    port ( clk                 : in std_logic;                          -- systen clock
           collision           : in std_logic;
           reset               : in std_logic;
           player_x            : out integer;
           player_y            : out integer;
           input               : in std_logic;                          -- keypress input
           new_column          : in std_logic;
           gap                 : out integer;
           height              : out integer;
           terrain_change      : in std_logic;
           speed               : out integer;
           score               : out std_logic_vector(15 downto 0));
    
  end component;

  -- intermediate signals between VGA_MOTOR and CPU  
  signal	player_x_s        : integer;                              -- players pixel-x
  signal	player_y_s        : integer;                              -- players pixel-y

  signal	collision       : std_logic;                            -- collision interrupt flag
  signal        input_local     : std_logic;                            -- input (from KBD_ENC to CPU)

  signal        new_column      : std_logic;                            -- flag for computing next column

  signal        gap_s           : integer;
  signal        height_s        : integer;
  signal        terrain_change_s : std_logic;
  signal        speed_s         : integer;

  
  
  signal        seg_cnt         : unsigned(15 downto 0) := (others => '0');
  signal        points          : std_logic_vector(15 downto 0) := "0000000100100011";
  signal        points_prev     : std_logic_vector(15 downto 0);
  signal        segments        : std_logic_vector(7 downto 0) := (others => '0');
  signal        seg_val         : std_logic_vector(3 downto 0) := (others => '0');
  signal        seg_dis         : std_logic_vector(3 downto 0) := (others => '0');
  constant      POINTS_LATENCY  : integer := 300000000;
  signal        points_counter  : integer;
  signal        point_wait      : std_logic := '0';
  
begin

  keypress <= input_local;

  -- keyboard encoder component connection
  KE : KBD_ENC port map(clk=>clk,
                        rst=>rst,
                        PS2KeyboardCLK=>PS2KeyboardCLK,
                        PS2KeyboardData=>PS2KeyboardData,
                        input=>input_local);
  
  -- VGA motor component connection
  VM : VGA_MOTOR port map(clk=>clk,
                          rst=>rst,
                          vgaRed=>vgaRed,
                          vgaGreen=>vgaGreen,
                          vgaBlue=>vgaBlue,
                          player_x=>player_x_s,
                          player_y=>player_y_s,
                          collision=>collision,
                          Hsync=>Hsync,
                          Vsync=>Vsync,
                          new_column=>new_column,
                          gap=>gap_s,
                          height=>height_s,
                          terrain_change=>terrain_change_s,
                          speed=>speed_s);

  -- CPU connector
  CP : CPU port map(clk=>clk,
                    collision=>collision,
                    reset=>rst,
                    player_x=>player_x_s,
                    player_y=>player_y_s,
                    input=>input_local,
                    new_column=>new_column,
                    gap=>gap_s,
                    height=>height_s,
                    terrain_change=>terrain_change_s,
                    speed=>speed_s,
                    score=>points);

  --7-seg point counter
  
  process(clk)                          --16-bit counter
  begin
    if rising_edge(clk) then
      if seg_cnt = "1111111111111111" then
        seg_cnt <= (others => '0');
      else
        seg_cnt <= (seg_cnt + 1);
      end if;
    end if;
  end process;

  with seg_cnt(15 downto 14) select seg_val <=
       points_prev(15 downto 12) when "00",
       points_prev(11 downto 8) when "01",
       points_prev(7 downto 4) when "10",
       points_prev(3 downto 0) when others;
  
  process(clk)
  begin
    if rising_edge(clk) then 
     case seg_val is
         when "0000" => segments <= "11000000";
         when "0001" => segments <= "11111001";
         when "0010" => segments <= "10100100";
         when "0011" => segments <= "10110000";
         when "0100" => segments <= "10011001";
         when "0101" => segments <= "10010010";
         when "0110" => segments <= "10000010";
         when "0111" => segments <= "11111000";
         when "1000" => segments <= "10000000";
         when "1001" => segments <= "10010000";
         when "1010" => segments <= "10001001";
         when "1011" => segments <= "11100001";
         when "1100" => segments <= "10110001";
         when "1101" => segments <= "11000011";
         when "1110" => segments <= "10110001";
         when others => segments <= "10111001";
    end case;
    case seg_cnt(15 downto 14) is
         when "00" => seg_dis <= "0111";
         when "01" => seg_dis <= "1011";
         when "10" => seg_dis <= "1101";
         when others => seg_dis <= "1110";
       end case;
                        
    end if;
  end process;

  seg <= segments;
  an <= seg_dis;


  -- Show points on display for a short while after collision
  process(clk)
  begin
    if rising_edge(clk) then

      -- If collision, stop updating the points
      if collision = '1' then
        point_wait <= '1';
        points_counter <= 0;

      -- If waited, reset points_counter and allow showing current points
      elsif points_counter > POINTS_LATENCY then
        points_counter <= 0;
        point_wait <= '0';

      -- While waiting, keep counting up until points_counter reaches POINTS_LATENCY
      elsif point_wait = '1' then
        points_counter <= points_counter + 1;

      -- If not waiting, make sure points_prev is updated to show points
      else
        points_prev <= points;
      end if;
        
    end if;
  end process;

  
end Behavioral;

