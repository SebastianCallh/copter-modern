-- copter_modern

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity copter_modern is
  port ( clk	                : in std_logic;                         -- system clock
	 rst                    : in std_logic;                         -- reset
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
           new_column           : out std_logic);
  end component;


  -- CPU
  component CPU
    port ( clk                 : in std_logic;                          -- systen clock
           collision           : in std_logic;
           reset               : in std_logic;
           player_x            : out integer;
           player_y            : out integer;
           input               : in std_logic;                          -- keypress input
           new_column          : in std_logic);
  end component;
	
  -- intermediate signals between PICT_MEM and VGA_MOTOR
  --signal	out_pixel       : std_logic_vector(7 downto 0);         -- data
  --signal	out_addr        : unsigned(10 downto 0);                -- address

  -- intermediate signals between VGA_MOTOR and CPU
  signal        pic_mem_we      : std_logic := '1';                     -- pic mem port 1 we
  signal	tile_data       : std_logic_vector(7 downto 0);         -- tile type to save
  
  signal	tile_x          : std_logic_vector(9 downto 0);         -- tile-x where to save it
  signal	tile_y          : std_logic_vector(8 downto 0);         -- tile-y where to save it
  
  signal	player_x_s        : integer;                              -- players pixel-x
  signal	player_y_s        : integer;                              -- players pixel-y
  
  signal	collision       : std_logic;                            -- collision interrupt flag
  signal        input_local     : std_logic;                            -- input (from KBD_ENC to CPU)

  signal        new_column      : std_logic;                            -- flag for computing next column
  
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
                          new_column=>new_column);

  -- CPU connector
  CP : CPU port map(clk=>clk,
                    collision=>collision,
                    reset=>rst,
                    player_x=>player_x_s,
                    player_y=>player_y_s,
                    input=>input_local,
                    new_column=>new_column);
  
end Behavioral;

