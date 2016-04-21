library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity copter_modern_tb is
end copter_modern_tb;

architecture Behavioral of copter_modern_tb is

  component copter_modern
      Port (clk : in std_logic;
            rst : in std_logic;
            PS2KeyboardCLK : in std_logic;
            PS2KeyboardData : in std_logic
            );
  end component;

  -- Testsignaler
  signal clk : std_logic;
  signal rst : std_logic;
  signal PS2KeyboardCLK : std_logic;
  signal PS2KeyboardData : std_logic;
begin

  main: copter_modern port map(clk => clk,
                               rst => rst,
                               PS2KeyboardCLK => PS2KeyboardCLK,
                               PS2KeyboardData => PS2KeyboardData);

  -- Klocksignal 100MHz
  clk <= not clk after 5 ns;

end;
