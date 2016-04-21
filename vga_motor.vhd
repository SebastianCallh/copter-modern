--------------------------------------------------------------------------------
-- VGA MOTOR
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity VGA_MOTOR is
  port ( clk			: in std_logic;
	 data			: in std_logic_vector(7 downto 0);
	 addr			: out unsigned(10 downto 0);
         pixel                  : in std_logic_vector(7 downto 0);
	 rst			: in std_logic;
	 vgaRed		        : out std_logic_vector(2 downto 0);
	 vgaGreen	        : out std_logic_vector(2 downto 0);
	 vgaBlue		: out std_logic_vector(2 downto 1);
	 Hsync		        : out std_logic;
	 Vsync		        : out std_logic);
end VGA_MOTOR;


-- architecture
architecture Behavioral of VGA_MOTOR is

  signal	Xpixel	        : unsigned(9 downto 0);         -- Horizontal pixel counter
  signal	Ypixel	        : unsigned(9 downto 0);		-- Vertical pixel counter
  signal	ClkDiv	        : unsigned(1 downto 0);		-- Clock divisor, to generate 25 MHz signal
  signal	Clk25		: std_logic;			-- One pulse width 25 MHz signal
		
  signal 	out_pixel       : std_logic_vector(7 downto 0);	-- Final pixel output
  signal	tileAddr	: unsigned(10 downto 0);	-- Tile address

  signal        blank           : std_logic;                    -- blanking signal
	
begin
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
          Xpixel <= "0000000000";
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
            Ypixel <= "0000000000";
          else
            Ypixel <= Ypixel + 1;
          end if;
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
  Blank <= '1' when Xpixel >= "1010000000" or Ypixel >= "111100000" else '0';
  
  -- Tile memory
process(clk)
  begin
    if rising_edge(clk) then
      if (blank = '0') then
        --tilePixel <= tileMem(to_integer(tileAddr));
        out_pixel <= std_logic_vector(pixel);
      else
        out_pixel <= (others => '0');
      end if;
    end if;
  end process;
	


  -- Tile memory address composite
  --tileAddr <= unsigned(data(4 downto 0)) & Ypixel(4 downto 2) & Xpixel(4 downto 2);


  -- Picture memory address composite
  --addr <= to_unsigned(20, 7) * Ypixel(8 downto 5) + Xpixel(9 downto 5);


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

