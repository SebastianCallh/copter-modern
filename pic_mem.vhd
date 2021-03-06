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
         offset         : in integer;
         gap            : in integer;
         height         : in integer;
         terrain_change : out std_logic);

end pic_mem;

	
-- architecture
architecture Behavioral of pic_mem is
  signal sprite_x_mod : integer;
  signal sprite_y_mod : integer;

  signal tile_pixel : std_logic_vector(7 downto 0);
  signal sprite_pixel : std_logic_vector(7 downto 0);
  signal background_pixel : std_logic_vector(7 downto 0) := "00000001";

  constant GRID_HEIGHT : integer := 60;
  constant GRID_WIDTH : integer := 128;
  constant SCREEN_HEIGHT : integer := 480;
  constant SCREEN_WIDTH : integer := 640;
  
  constant TILE_SIZE : integer := 8;
  constant SPRITE_SIZE : integer := 32;


  -- The grid which makes up the terrain of the game
  -- 8x8 Tile grid (1024 / 8) * (480 / 8) = 128 * 60 = 4800 => 4096
  type grid_ram is array (0 to 7679) of std_logic_vector(0 downto 0);
  signal grid_mem : grid_ram := ("0",  others => "0");



  
  -- 16x16 Sprite memory 16*16 = 256  (This is the copter design)
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

  -- after this many pixels have scrolled by the terrain will change
  constant TERRAIN_CHANGE_LATENCY : integer := 8;  

  -- Grid building signals
  signal new_col, new_col_start, q, q_plus : std_logic;
  signal current_row : integer := 0;
  
 
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


		  x"49",x"49",x"92",x"92",x"92",x"92",x"92",x"92",	-- BlockOfRock
		  x"49",x"92",x"25",x"25",x"25",x"92",x"92",x"92",
		  x"92",x"25",x"24",x"49",x"25",x"92",x"92",x"92",
		  x"92",x"92",x"25",x"24",x"49",x"25",x"92",x"49",
		  x"92",x"92",x"25",x"49",x"25",x"92",x"92",x"49",
		  x"92",x"92",x"92",x"25",x"92",x"92",x"92",x"92",
		  x"92",x"92",x"92",x"49",x"49",x"92",x"92",x"92",
		  x"92",x"92",x"49",x"49",x"49",x"92",x"92",x"92");

                  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92",	-- One color
		  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92",
		  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92",
		  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92",
		  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92",
		  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92",
		  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92",
		  --x"92",x"92",x"92",x"92",x"92",x"92",x"92",x"92");

                  


begin

  -- The offset is how long into our tile grid we've traveller
  -- The grid loos every 1024 tiles

  --Offset
  offset_x <= (pixel_x + offset) mod 1024;

  --Grid coord
  grid_coord_x <= offset_x(10 downto 3);
  grid_coord_y <= pixel_y(9 downto 3);

  --Sub pixel
  tile_sub_x <= offset_x(2 downto 0);
  tile_sub_y <= pixel_y(2 downto 0);
  tmp_tile_addr <= (conv_integer(tile_addr) * TILE_SIZE * TILE_SIZE) + (to_integer(tile_sub_y) * TILE_SIZE) + to_integer(tile_sub_x);

  
  --grid memory
  process(clk)
    begin
      if rising_edge(clk) then
        if (we = '1') then
          grid_mem(conv_integer(tile_y) * SCREEN_WIDTH +
                    conv_integer(tile_x)) <= data_in;
        end if;
          tile_addr <= grid_mem((to_integer(grid_coord_y) * GRID_WIDTH) + to_integer(grid_coord_x));
      end if;

    end process;
 
  --tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      tile_pixel <= tile_mem(tmp_tile_addr);
    end if;
  end process;

  --modulus sprite_size
  sprite_x_mod <= (to_integer(pixel_x) - player_x) /2;  -- mod 16
  sprite_y_mod <= (to_integer(pixel_y) - player_y) /2;  -- mod 16
  
  --sprite memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (pixel_x >= player_x) and (pixel_y >= player_y) then
        if (pixel_x < (player_x + SPRITE_SIZE)) and (pixel_y < (player_y + SPRITE_SIZE)) then         
          sprite_pixel <= sprite_mem(((sprite_y_mod * (SPRITE_SIZE/2)) + sprite_x_mod) mod 256);
        else
          sprite_pixel <= x"00";
        end if;
      else
          sprite_pixel <= x"00";
      end if;
    end if;
  end process;

  --pixel chooser
  -- Sends the right pixel to out_pixel and sends collision signal
  -- when the player overlaps with a non-transparent pixel in tile_grid
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




 -- Sends a signal when the terrain should be updated 
  terrain_change <= '1' when (offset mod TERRAIN_CHANGE_LATENCY) = 1 else
                    '0';
  
  process(clk)
  begin
    if rising_edge(clk) then
      q <= q_plus;
    end if;
  end process;

 q_plus <= '1' when (offset mod TERRAIN_CHANGE_LATENCY) = 0 else
           '0';
  
 new_col_start <= not q and q_plus;
 
  -- Grid builder
  process(clk)
  begin
    if rising_edge(clk) then

      -- Check if it's time to start building a new column
      if new_col_start = '1' then
        new_col <= '1';
        current_row <= 0;

      -- When at the last row (60) then disable grid building, reset row counter
      elsif current_row = 60 then
        current_row <= 0;
        new_col <= '0';

      -- While grid building is enabled, place the correct tile type at the
      -- current spot in the grid, depending on current height and gap
      elsif new_col = '1' then
        if current_row < height or current_row > (height + gap) then
          grid_mem((((127 + (offset mod 1024)/8)) mod 128) + (128*current_row)) <= "1";
        else
          grid_mem((((127 + (offset mod 1024)/8)) mod 128) + (128*current_row)) <= "0";
        end if;
        current_row <= current_row + 1;
      end if;
    end if;
  end process;

  
end Behavioral;
