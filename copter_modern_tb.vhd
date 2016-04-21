library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity copter_modern_tb is
end copter_modern_tb;

architecture Behavioral of copter_modern_tb is

  component copter_modern_lab
      Port (clk : in std_logic);
  end component;

  -- Testsignaler
  signal clk : std_logic;
begin

  main: copter_modern_lab port map(clk => clk);

  -- Klocksignal 100MHz
  clk <= not clk after 5 ns;

end;
