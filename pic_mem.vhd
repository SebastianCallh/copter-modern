-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.std_logic_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

-- entity
entity pic_mem is
  port ( clk		: in std_logic;
         we		: in std_logic;
         data_in	: in std_logic_vector(0 downto 0);
         tile_x         : in std_logic_vector(7 downto 0);
         tile_y         : in std_logic_vector(6 downto 0);
         player_x       : in integer;
         player_y       : in integer;
         out_pixel	: out std_logic_vector(7 downto 0);
         pixel_x        : in unsigned(10 downto 0);
         pixel_y        : in unsigned(9 downto 0);
         collision      : out std_logic;
         offset         : in integer);

end pic_mem;

	
-- architecture
architecture Behavioral of pic_mem is
  signal sprite_x_mod : integer range 0 to 15;
  signal sprite_y_mod : integer range 0 to 15;

  signal tile_pixel : std_logic_vector(7 downto 0);
  signal sprite_pixel : std_logic_vector(7 downto 0);
  signal background_pixel : std_logic_vector(7 downto 0) := "00000001";

  constant GRID_HEIGHT : integer := 60;
  constant GRID_WIDTH : integer := 128;
  constant SCREEN_HEIGHT : integer := 480;
  constant SCREEN_WIDTH : integer := 640;
  
  constant TILE_SIZE : integer := 8;
  constant SPRITE_SIZE : integer := 16;
  
  -- 8x8 Tile grid (1024 / 8) * (480 / 8) = 128 * 60 = 4800 => 4096
  type grid_ram is array (0 to 7679) of std_logic_vector(0 downto 0);
  signal grid_mem : grid_ram := ("0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", others => "0");

  -- 16x16 Sprite memory 16*16 = 256
  type sprite_ram is array (0 to 255) of std_logic_vector(7 downto 0);
  signal sprite_mem : sprite_ram := (x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                     x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"00",x"00",x"00",
                                     x"FF",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"1F",x"1F",x"1F",x"FF",x"FF",x"00",x"00",x"00",
                                     x"E0",x"FF",x"00",x"00",x"00",x"00",x"FF",x"FF",x"1F",x"1F",x"1F",x"1F",x"FF",x"00",x"00",x"00",
                                     x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"1F",x"1F",x"FF",x"00",x"00",
                                     x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"03",x"03",x"03",x"FF",x"FF",x"FF",x"FF",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",x"00",x"00",x"00",x"FF",x"00",x"00",x"FF",x"00",
                                     x"00",x"00",x"00",x"00",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                                     x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00");

  
  signal tile_addr : std_logic_vector(0 downto 0);
  signal grid_coord_x : unsigned(7 downto 0); -- x tile coordinate
  signal grid_coord_y : unsigned(6 downto 0); -- y tile coordinate
  signal tile_sub_x : unsigned(2 downto 0); -- x pixel in the tile
  signal tile_sub_y : unsigned(2 downto 0); -- y pixel in the tile
  signal tmp_tile_addr : integer;
  signal offset_x                : unsigned (10 downto 0);

 
  -- Tile_memory type
  type tile_ram is array (0 to 127) of std_logic_vector(7 downto 0);
  signal tile_mem : tile_ram := 
		( x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",      -- Transparent
                  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
                  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

		  x"49",x"49",x"92",x"92",x"92",x"92",x"92",x"92",	-- A
		  x"49",x"92",x"25",x"25",x"25",x"92",x"92",x"92",
		  x"92",x"25",x"24",x"49",x"25",x"92",x"92",x"92",
		  x"92",x"92",x"25",x"24",x"49",x"25",x"92",x"49",
		  x"92",x"92",x"25",x"49",x"25",x"92",x"92",x"49",
		  x"92",x"92",x"92",x"25",x"92",x"92",x"92",x"92",
		  x"92",x"92",x"92",x"49",x"49",x"92",x"92",x"92",
		  x"92",x"92",x"49",x"49",x"49",x"92",x"92",x"92");

begin

  offset_x <= (pixel_x + offset) mod 1024;
  grid_coord_x <= offset_x(10 downto 3);
  grid_coord_y <= pixel_y(9 downto 3);
  tile_sub_x <= offset_x(2 downto 0);
  tile_sub_y <= pixel_y(2 downto 0);
  tmp_tile_addr <= (conv_integer(tile_addr) * TILE_SIZE * TILE_SIZE) + (to_integer(tile_sub_y) * TILE_SIZE) + to_integer(tile_sub_x);

  
  --grid memory
  process(clk)
    begin
      if rising_edge(clk) then
        if (we = '1') then
          --GER FATAL ERROR VID SIMULERING
          grid_mem(conv_integer(tile_y) * SCREEN_WIDTH +
                    conv_integer(tile_x)) <= data_in;
        end if;
      end if;
      tile_addr <= grid_mem((to_integer(grid_coord_y) * GRID_WIDTH) + to_integer(grid_coord_x));
    end process;
 
  --tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      tile_pixel <= tile_mem(tmp_tile_addr);
    end if;
  end process;

  --modulus sprite_size
  sprite_x_mod <= (to_integer(pixel_x) - player_x);  -- mod 16
  sprite_y_mod <= (to_integer(pixel_y) - player_y);  -- mod 16
  
  --sprite memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (pixel_x >= player_x) and (pixel_y >= player_y) then
        if (pixel_x < (player_x + SPRITE_SIZE)) and (pixel_y < (player_y + SPRITE_SIZE)) then
          end if;
          sprite_pixel <= sprite_mem((sprite_y_mod * SPRITE_SIZE) + sprite_x_mod);
        else
          sprite_pixel <= x"00";
        end if;
      else
          sprite_pixel <= x"00";
      end if;
    end if;
  end process;

  --pixel chooser
  process (clk)
  begin
    if rising_edge(clk) then
      if sprite_pixel /= x"00" then
        out_pixel <= sprite_pixel;
        if tile_addr /= "0" then
          collision <= '1';
        else
          collision <= '0';
        end if;
      elsif tile_pixel /= x"00" then
        out_pixel <= tile_pixel;
        collision <= '0';
      else
        out_pixel <= background_pixel;
        collision <= '0';
      end if;
    end if;
  end process;
  
end Behavioral;
