library ieee;
use ieee.std_logic_1164.all;

entity archangel is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end entity;

architecture rtl of archangel is
    
begin

cnt : entity work.timer
port map (
    clk   => clk,
    reset => reset
);

end architecture;