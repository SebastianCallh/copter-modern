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
	 Hsync	                : out std_logic;                        -- horizontal sync
	 Vsync	                : out std_logic;                        -- vertical sync
	 vgaRed	                : out	std_logic_vector(2 downto 0);   -- VGA red
	 vgaGreen               : out std_logic_vector(2 downto 0);     -- VGA green
	 vgaBlue	        : out std_logic_vector(2 downto 1);     -- VGA blue
	 PS2KeyboardCLK	        : in std_logic;                         -- PS2 clock
	 PS2KeyboardData        : in std_logic);                        -- PS2 data
end copter_modern;


-- architecture
architecture Behavioral of copter_modern is

  -- PS2 keyboard encoder component
  component KBD_ENC
    port ( clk		        : in std_logic;				-- system clock
	   rst		        : in std_logic;				-- reset signal
	   PS2KeyboardCLK       : in std_logic;				-- PS2 clock
	   PS2KeyboardData      : in std_logic;				-- PS2 data
	   data		        : out std_logic_vector(7 downto 0);	-- tile data
	   addr			: out unsigned(10 downto 0);	        -- tile address
	   we			: out std_logic);	                -- write enable
  end component;

  -- picture memory component
  component PIC_MEM
    port ( clk			: in std_logic;                         -- system clock
           we		        : in std_logic;                         -- write enable
           tile_in	        : in std_logic_vector(7 downto 0);      -- data in
           tile_x               : in unsigned(9 downto 0);              -- address
           tile_y               : in unsigned(8 downto 0);              -- address
           out_pixel	        : out std_logic_vector(7 downto 0);     -- data out
           out_addr		: in unsigned(10 downto 0);             -- adress
           collision            : out std_logic);
  end component;
	
  -- VGA motor component
  component VGA_MOTOR
    port ( clk			: in std_logic;                         -- system clock
           rst			: in std_logic;                         -- reset
           pixel                : in std_logic_vector(7 downto 0);
           data			: in std_logic_vector(7 downto 0);      -- data
           vgaRed		: out std_logic_vector(2 downto 0);     -- VGA red
           vgaGreen	        : out std_logic_vector(2 downto 0);     -- VGA green
           vgaBlue		: out std_logic_vector(2 downto 1);     -- VGA blue
           Hsync		: out std_logic;                        -- horizontal sync
           Vsync		: out std_logic);                       -- vertical sync
  end component;


  -- CPU
  component CPU
    port ( clk                 : in std_logic;                          -- systen clock
           collision           : in std_logic;
           reset               : in std_logic;
           input               : in std_logic                           -- keypress input
       );
           
  end component;
	
  -- intermediate signals between KBD_ENC and PICT_MEM
  signal        data_s	        : std_logic_vector(7 downto 0);         -- data
  signal	addr_s	        : unsigned(10 downto 0);                -- address
  signal	we_s		: std_logic;                            -- write enable
	
  -- intermediate signals between PICT_MEM and VGA_MOTOR
  signal	out_pixel       : std_logic_vector(7 downto 0) :="00011100";         -- data
  signal	out_addr        : unsigned(10 downto 0);                -- address

  -- intermediate signals between PIC_MEM and CPU
  signal        pic_mem_we      : std_logic := '1';                     -- pic mem port 1 we
  signal	tile_data       : std_logic_vector(7 downto 0);         -- tile type to save
  
  signal	tile_x          : std_logic_vector(9 downto 0);         -- tile-x where to save it
  signal	tile_y          : std_logic_vector(8 downto 0);         -- tile-y where to save it
  
  signal	player_x        : std_logic_vector(7 downto 0);         -- players pixel-x
  signal	player_y        : std_logic_vector(7 downto 0);         -- players pixel-y
  
  signal	collision       : std_logic := '0';                     -- collision interrupt flag

  
begin

  -- keyboard encoder component connection
  KE : KBD_ENC port map(clk=>clk,
                        rst=>rst,
                        PS2KeyboardCLK=>PS2KeyboardCLK,
                        PS2KeyboardData=>PS2KeyboardData,
                        data=>data_s,
                        addr=>addr_s,
                        we=>we_s);

-- picture memory component connection
--  PM : PIC_MEM port map(clk=>clk,
--                        we=>pic_mem_we,
--                        tile_in=>tile_data,
--                        tile_x=>tile_x,
--                        tile_y=>tile_y,
--                        out_pixel=>out_pixel,
--                        out_addr=>out_addr,
--                        collision=>collision);
  
  -- VGA motor component connection
  VM : VGA_MOTOR port map(clk=>clk,
                          data=>out_pixel,
                          pixel=>out_pixel,
                          rst=>rst,
                          vgaRed=>vgaRed,
                          vgaGreen=>vgaGreen,
                          vgaBlue=>vgaBlue,
                          Hsync=>Hsync,
                          Vsync=>Vsync);

  -- CPU connector
  CP : CPU port map (clk => clk,
                     collision=>collision,
                     reset=>rst,
                     input=>PS2KeyboardData);

end Behavioral;

