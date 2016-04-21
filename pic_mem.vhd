-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.std_logic_unsigned.ALL;
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity PIC_MEM is
  port ( clk		: in std_logic;
         -- port 1
         we		: in std_logic;
         data_in	: in std_logic_vector(7 downto 0);
         tile_x         : in std_logic_vector(9 downto 0);
         tile_y         : in std_logic_vector(8 downto 0);
         player_x       : in integer;
         player_y       : in integer;
         -- port 2
         out_pixel	: out std_logic_vector(7 downto 0);
         out_addr       : in std_logic_vector(10 downto 0);
         collision      : out std_logic);

end PIC_MEM;

	
-- architecture
architecture Behavioral of PIC_MEM is

  signal tile_type : std_logic;
  signal tile_int : integer;
  
  signal x_internal : std_logic_vector(9 downto 0);
  signal y_internal : std_logic_vector(8 downto 0);

  signal x_mod_tile_s : integer range 0 to 7;
  signal y_mod_tile_s : integer range 0 to 7;

  signal x_mod_sprite_s : integer range 0 to 15;
  signal y_mod_sprite_s : integer range 0 to 15;

  signal tile_pixel : std_logic_vector(7 downto 0);
  signal sprite_pixel : std_logic_vector(7 downto 0);
  signal background_pixel : std_logic_vector(7 downto 0);
  
  -- tile_grid type (61 * 34 = 2074)
  type tile_grid is array (0 to 2074) of std_logic;
  signal tiles : tile_grid := ('0','1','0','0','1','0','1','0','0','1','0','1','0','0','1','0',
                                       '1','0','0','1','0','1','0','0','1','0','1','0','0','1','0','1',
                                       '0','0','1','0','1','0','0','1','0','1','0','0','1','0','1','0',
                                       '0','1','0','1','0','0','1','0','1','0','0','1','0','1','0','0',others =>'0');

    --sprite_memory type
  type sprite_ram is array (0 to 255) of std_logic_vector(7 downto 0);
  signal sprite_mem : sprite_ram := (others => "00000011");

  -- Tile_memory type
  type tile_ram is array (0 to 127) of std_logic_vector(7 downto 0);
  signal tile_mem : tile_ram := 
		( x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",      -- space
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",

		  x"FF",x"FF",x"00",x"00",x"00",x"FF",x"FF",x"FF",	-- A
		  x"FF",x"00",x"00",x"FF",x"00",x"00",x"FF",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"00",x"00",x"FF",x"FF",x"FF",x"00",x"00",x"FF",
		  x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF",x"FF");

begin
  --set tile int
  tile_int <= 1 when tile_type = '1' else 0;

  --tile_grid memory
  process(clk)
    begin
      if rising_edge(clk) then
        if (we = '1') then
          --code for port 1 (CPU)
        end if;
        tile_type <= tiles(conv_integer(out_addr));
--fel "måste heltalsdivideras med tile-storlek"




--SÅ ATT VI INTE GLÖMMER BORT
--I och med att våra tiles kommer vara multiplar av 2 breda och höga
--kan vi bara maska ut de t.ex. 3 MSB för att göra modulu 8.
--I och med att skärmen nu är 640 * 480 kan vi ha
--640 / 8 = 80, 480 / 8 = 60 tiles om de är 8x8.
        
      end if;
    end process;
    
  --modulus tile_size
  x_mod_tile_s <= conv_integer(x_internal) mod 8;
  y_mod_tile_s <= conv_integer(y_internal) mod 8;

  --flip-flopp
--  process(clk)
--  begin  
--    if rising_edge(clk) then
--      x_internal <= x2;
--      y_internal <= y2;
--    end if;
--  end process;

  --Tile memory
  process(clk)
  begin
    if rising_edge(clk) then
      tile_pixel <= tile_mem((y_mod_tile_s*8) + x_mod_tile_s + tile_int*64);
    end if;
  end process;

  --modulus sprite_size
  x_mod_sprite_s <= player_x mod 16;
  y_mod_sprite_s <= player_y mod 16;
  
  
  --sprite memory
  process(clk)
  begin
    if rising_edge(clk) then
      if (x_internal >= player_x) and (y_internal >= player_y) then
        if (x_internal < (player_x+16)) and (y_internal < (player_y+16)) then
          sprite_pixel <= sprite_mem((y_mod_sprite_s*16) + x_mod_sprite_s);
        else
          sprite_pixel <= x"00";
        end if;
      end if;
    end if;
  end process;


  --pixel chooser
  process (clk)
  begin
    if rising_edge(clk) then
      if sprite_pixel /= x"00" then
        out_pixel <= sprite_pixel;
        if tile_pixel /= x"00" then
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
