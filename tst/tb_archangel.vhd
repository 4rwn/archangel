library ieee;
use ieee.std_logic_1164.all;

entity tb_archangel is
end entity;

architecture rtl of tb_archangel is
    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
begin

clk <= not clk after CLK_PERIOD / 2;

dut: entity work.archangel
port map (
    clk   => clk,
    reset => reset
);

process
begin
    reset <= '1';

    wait for 5 * CLK_PERIOD;
    reset <= '0';

    wait for 20 us;
    std.env.stop;
    wait;
end process;
end architecture;