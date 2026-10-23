library ieee;
use ieee.std_logic_1164.all;

entity tb_archangel is
end entity;

architecture rtl of tb_archangel is
    constant CLK100M_PERIOD : time := 10 ns;

    signal clk100M : std_logic := '0';

    signal enet_mdc : std_logic := '0';
    signal enet_mdio : std_logic := '0';
begin

clk100M <= not clk100M after CLK100M_PERIOD / 2;

dut: entity work.archangel
port map (
    clk100M_i => clk100M,

    enet_mdc_o => enet_mdc,
    enet_mdio_io => enet_mdio
);

process
begin
    wait for 2 ms;
    std.env.stop;
    wait;
end process;
end architecture;