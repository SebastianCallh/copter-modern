--------------------------------------------------------------------------------
-- VGA MOTOR
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
use IEEE.std_logic_unsigned.ALL;



-- entity
entity VGA_MOTOR is
  port ( clk			: in std_logic;
	 rst			: in std_logic;
	 vgaRed		        : out std_logic_vector(2 downto 0);
	 vgaGreen	        : out std_logic_vector(2 downto 0);
	 vgaBlue		: out std_logic_vector(2 downto 1);
	 Hsync		        : out std_logic;
	 Vsync		        : out std_logic;
         player_x               : in integer;
         player_y               : in integer;
         collision              : out std_logic;
         new_column             : out std_logic;
         gap                    : in integer;
         height                 : in integer;
         terrain_change         : out std_logic;
         speed                  : in integer);
  
end VGA_MOTOR;

-- architecture
architecture Behavioral of VGA_MOTOR is

  signal	Xpixel	        : unsigned(10 downto 0) := (others => '0');     -- Horizontal pixel counter
  signal	Ypixel	        : unsigned(9 downto 0) := (others => '0');      -- Vertical pixel counter
  signal	ClkDiv	        : unsigned(1 downto 0) := (others => '0');	-- Clock divisor, to generate 25 MHz signal
  signal	Clk25		: std_logic;		                	-- One pulse width 25 MHz signal
  signal 	out_pixel       : std_logic_vector(7 downto 0) := "00000011";	-- Final pixel output
  signal        blank           : std_logic;                                    -- blanking signal        
  constant      TILE_SIZE       : integer := 8;

  --temporary signals to only test pushing data from memory to scre
  -- port 1
  signal data_in	: std_logic_vector(0 downto 0) := "0";
  signal tile_x         : std_logic_vector(7 downto 0) := "10101010";
  signal tile_y         : std_logic_vector(6 downto 0) := "1010101";
  -- port 2
  signal pixel_from_pic_mem : std_logic_vector(7 downto 0);

  signal offset                  : integer := 0;
  signal offset_count            : std_logic_vector(20 downto 0) := (others => '0');
  signal offset_clk              : std_logic;
  signal OFFSET_UPDATE_LATENCY   : integer;
  signal offset_enable           : std_logic := '1';


  signal coll : std_logic;
  signal col_count : integer := 0;    -- keeps track of how many cols have updated
  signal coll_prev : std_logic;
  signal coll_alert : std_logic;
  signal rst_prev : std_logic;
  signal rst_alert : std_logic;
  
  component pic_mem is
    port ( clk		: in std_logic;
           we		: in std_logic;
           data_in	: in std_logic_vector(0 downto 0);
           tile_x         : in std_logic_vector(7 downto 0);
           tile_y         : in std_logic_vector(6 downto 0);
           player_x       : in integer;
           player_y       : in integer;
           out_pixel	  : out std_logic_vector(7 downto 0);
           pixel_x        : in unsigned(10 downto 0);
           pixel_y        : in unsigned(9 downto 0);
           collision      : out std_logic;
           offset         : in integer;
           gap            : in integer;
           height         : in integer;
           terrain_change : out std_logic);
  end component;
begin

  collision <= coll;
  
  PM : pic_mem port map (clk=>clk,
                         we=>'0',
                         data_in=>data_in,
                         tile_x=>tile_x,
                         tile_y=>tile_y,
                         player_x=>player_x,
                         player_y=>player_y,
                         out_pixel=>pixel_from_pic_mem,
                         pixel_x=>Xpixel,
                         pixel_y=>Ypixel,
                         collision=>coll,
                         offset=>offset,
                         gap=>gap,
                         height=>height,
                         terrain_change=>terrain_change);

  -- Clock divisor
  -- Divide system clock (100 MHz) by 4
  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
	ClkDiv <= (others => '0');
      else
	ClkDiv <= ClkDiv + 1;
      end if;
    end if;
  end process;
	
  -- 25 MHz clock (one system clock pulse width)
  Clk25 <= '1' when (ClkDiv = 3) else '0';

  
  -- Timer for the offset updating speed
  process(clk)
  begin
    if rising_edge(clk) then
      if offset_count = OFFSET_UPDATE_LATENCY then
        offset_count <= (others => '0');                        
      else
	offset_count <= offset_count + 1;
      end if;
    end if;
  end process;

  -- Signals a new column every TILE_SIZE offset
  process (clk)
  begin
    if rising_edge(clk) then
      if (offset mod TILE_SIZE) = 0 then
        new_column <= '1';
      end if;
    end if;
  end process;

  -- Responds to dispatched interrupts and alert signals
  process(clk)
  begin
    if rising_edge(clk) then
      if (rst_alert = '1' or coll_alert = '1') and offset_clk = '1' then
        offset_enable <= '0';
        OFFSET_UPDATE_LATENCY <= 30;                             
        col_count <= col_count + 1;
      elsif col_count = 1024 then
        offset_enable <= '1';
        OFFSET_UPDATE_LATENCY <= speed*1000;
        coll_alert <= '0';
        rst_alert <= '0';
        col_count <= 0;

      elsif offset_enable = '1' then
        OFFSET_UPDATE_LATENCY <= speed*1000;  
      end if;

      if rst = '1' and rst_prev = '0' then
        rst_alert <= '1';
      end if;
      if coll = '1' and coll_prev = '0' then
        coll_alert <= '1';
      end if;

      rst_prev <= rst;
      coll_prev <= coll;
    end if;
  end process;
  
  -- 25 MHz clock (one system clock pulse width)
  offset_clk <= '1' when (offset_count = OFFSET_UPDATE_LATENCY) else '0';

	
  -- Horizontal pixel counter

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Xpixel                         *
  -- *                                 *
  -- ***********************************
  
  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' then
        -- 800
        if Xpixel = "1100100000" then
          Xpixel <= (others => '0');
        else
          Xpixel <= Xpixel + 1;
        end if;
      end if;
      
    end if; 
  end process;
--800
  -- Horizontal sync

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Hsync                          *
  -- *                                 *
  -- ***********************************


  -- 565 - 752
  
  Hsync <= '1' when "1000110101" <= Xpixel and Xpixel <= "1011110000" else '0';
  

  
  -- Vertical pixel counter

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Ypixel                         *
  -- *                                 *
  -- ***********************************
  process(clk)
  begin
    if rising_edge(clk) then
      if Clk25 = '1' then      
        -- 800
        if Xpixel = "1100100000" then
          --521
          if Ypixel = "1000010001" then
            Ypixel <= (others => '0');
          else
            Ypixel <= Ypixel + 1;
          end if;
        end if;
      end if;
    end if;
  end process;



  --Offset counter
  process(clk)
  begin
    if rising_edge(clk) then
      if offset_clk = '1' then
        if offset = 1024 then
          offset <= 0;
        else
          offset <= offset + 1;
        end if;
      end if;
    end if;
  end process;
  
  -- 521

  -- Vertical sync

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Vsync                          *
  -- *                                 *
  -- ***********************************

  -- 490 - 492
  Vsync <= '1' when "111101010" <= Ypixel and Ypixel <= "111101100" else '0';

  
  -- Video blanking signal

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  Blank                          *
  -- *                                 *
  -- ***********************************

  -- 640 480
  blank <= '1' when Xpixel >= "1010000000" or Ypixel >= "111100000" else '0';

  -- Process for blanking out pixels when needed
  process(clk)
  begin
    if rising_edge(clk) then
      if (blank = '0') then
        out_pixel <= pixel_from_pic_mem;
      else
        out_pixel <= (others => '0');
      end if;
    end if;
  end process;

  -- VGA generation
  vgaRed(2) 	<= out_pixel(7);
  vgaRed(1) 	<= out_pixel(6);
  vgaRed(0) 	<= out_pixel(5);
  vgaGreen(2)   <= out_pixel(4);
  vgaGreen(1)   <= out_pixel(3);
  vgaGreen(0)   <= out_pixel(2);
  vgaBlue(2) 	<= out_pixel(1);
  vgaBlue(1) 	<= out_pixel(0);


end Behavioral;

