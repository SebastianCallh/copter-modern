--------------------------------------------------------------------------------
-- KBD ENC
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type
                                        -- and various arithmetic operations

-- entity
entity KBD_ENC is
  port ( clk	                : in std_logic;			-- system clock (100 MHz)
	 rst		        : in std_logic;			-- reset signal
         PS2KeyboardCLK	        : in std_logic; 		-- USB keyboard PS2 clock
         PS2KeyboardData	: in std_logic;			-- USB keyboard PS2 data
         input                  : out std_logic);               -- input flag
end KBD_ENC;

-- architecture
architecture behavioral of KBD_ENC is
  signal PS2Clk			: std_logic;			-- Synchronized PS2 clock
  signal PS2Data		: std_logic;			-- Synchronized PS2 data
  signal PS2Clk_Q1, PS2Clk_Q2 	: std_logic;			-- PS2 clock one pulse flip flop
  signal PS2Clk_op 		: std_logic;			-- PS2 clock one pulse 
	
  signal PS2Data_sr 		: std_logic_vector(10 downto 0);-- PS2 data shift register
	
  signal PS2BitCounter	        : unsigned(3 downto 0);		-- PS2 bit counter
  signal make_Q			: std_logic;			-- make one pulselse flip flop
  signal make_op		: std_logic;			-- make one pulse

  type state_type is (IDLE, MAKE, BREAK);			-- declare state types for PS2
  signal PS2state : state_type;					-- PS2 state

  signal ScanCode		: std_logic_vector(7 downto 0);	-- scan code
  
  signal BC11 : std_logic;
begin

  -- Synchronize PS2-KBD signals
  process(clk)
  begin
    if rising_edge(clk) then
      PS2Clk <= PS2KeyboardCLK;
      PS2Data <= PS2KeyboardData;
    end if;
  end process;

	
  -- Generate one cycle pulse from PS2 clock, negative edge

  process(clk)
  begin
    if rising_edge(clk) then
      if rst='1' then
        PS2Clk_Q1 <= '1';
        PS2Clk_Q2 <= '0';
      else
        PS2Clk_Q1 <= PS2Clk;
        PS2Clk_Q2 <= not PS2Clk_Q1;
      end if;
    end if;
  end process;
	
  PS2Clk_op <= (not PS2Clk_Q1) and (not PS2Clk_Q2);
	
  
  -- PS2 data shift register

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_data_shift_reg             *
  -- *                                 *
  -- ***********************************

  process(clk)
  begin
    if rising_edge(clk) then
      if PS2Clk_op = '1' then
        PS2Data_sr <= to_stdlogicvector(to_bitvector(PS2Data_sr) srl 1);
        PS2Data_sr(10) <= PS2Data;

        PS2Data_sr <= PS2Data & PS2Data_sr(10 downto 1);

      end if;
    end if;
  end process;
  
  ScanCode <= PS2Data_sr(8 downto 1);

  with ScanCode select
    input <= '1' when x"29",	-- space
             '0' when others;

  
  
  -- PS2 bit counter
  -- The purpose of the PS2 bit counter is to tell the PS2 state machine when to change state

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_bit_Counter                *
  -- *                                 *
  -- ***********************************
  process(clk)
  begin
    if rising_edge(clk) then
      if PS2Clk_op = '1' then
        if PS2BitCounter = "1010" then 
          PS2BitCounter <= "0000";
          BC11 <= '1';
        else
          PS2BitCounter <= PS2BitCounter + 1;
          BC11 <= '0';
        end if;
      else
        BC11 <= '0';
      end if;   
    end if;   
end process;
	
  -- PS2 state
  -- Either MAKE or BREAK state is identified from the scancode
  -- Only single character scan codes are identified
  -- The behavior of multiple character scan codes is undefined

  -- ***********************************
  -- *                                 *
  -- *  VHDL for :                     *
  -- *  PS2_State                      *
  -- *                                 *
  -- ***********************************

  process(clk)
  begin
    if rising_edge(clk) then
      if PS2State = IDLE then
        if BC11 = '1' and ScanCode /= "11110000" then
          PS2State <= MAKE;
        end if;
        if BC11 = '1' and Scancode = "11110000" then
          PS2State <= BREAK;
        end if;
      end if;

      if  PS2State = MAKE then
        PS2State <= IDLE;
      end if;

      if PS2State = BREAK then
        if BC11 = '1' then
          PS2State <= IDLE;
        end if;
      end if;
    end if;
  end process;
  
end behavioral;
