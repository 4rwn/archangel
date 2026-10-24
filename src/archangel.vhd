library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity archangel is
    port (
        clk100M_i : in std_logic;

        enet_mdc_o : out std_logic;
        enet_mdio_io : inout std_logic;
        enet_resetn_1v8_o : out std_logic
    );
end entity;

architecture rtl of archangel is
    signal mdc : std_logic := '0';
    signal mdio_tx_en : std_logic := '0';
    signal mdio_tx : std_logic := '0';
    signal mdio_rx : std_logic := '0';

    signal clk2M5_rise_en : std_logic := '0';
    signal clk2M5_fall_en : std_logic := '0';

    signal mdio_start : std_logic := '0';
    signal mdio_phy_addr : unsigned(3 downto 0) := (others => '0');

    signal cnt : unsigned(29 downto 0) := (0 => '1', others => '0');
begin

process (clk100M_i)
    constant CLK2M5_DIVIDER : integer := 40;

    variable clk2M5_counter : unsigned(4 downto 0) := (others => '0');
begin
    if rising_edge(clk100M_i) then
        clk2M5_rise_en <= '0';
        clk2M5_fall_en <= '0';

        clk2M5_counter := clk2M5_counter + 1;
        if clk2M5_counter = CLK2M5_DIVIDER / 2 then
            clk2M5_counter := (others => '0');

            mdc <= not mdc;
            if mdc = '0' then
                clk2M5_rise_en <= '1';
            else
                clk2M5_fall_en <= '1';
            end if;
        end if;
    end if;
end process;

process (clk100M_i)
begin
    if rising_edge(clk100M_i) then
        mdio_start <= '0';
        cnt <= cnt + 1;
        if cnt = 0 then
            mdio_start <= '1';
        end if;
        if mdio_start = '1' then
            mdio_phy_addr <= mdio_phy_addr + 1;
        end if;
    end if;
end process;

mdio : entity work.mdio
port map (
    clk100M_i => clk100M_i,
    clk2M5_rise_en_i => clk2M5_rise_en,
    clk2M5_fall_en_i => clk2M5_fall_en,

    start_i => mdio_start,
    rd_nwr_i => '1',
    phy_addr_i(4) => '0',
    phy_addr_i(3 downto 0) => std_logic_vector(mdio_phy_addr),
    reg_addr_i => "00010",
    data_i => (others => '0'),

    done_o => open,
    data_o => open,
    err_o => open,

    mdio_tx_en_o => mdio_tx_en,
    mdio_tx_o => mdio_tx,
    mdio_rx_i => mdio_rx
);

enet_mdc_o <= mdc;
enet_mdio_io <= '0' when mdio_tx_en = '1' and mdio_tx = '0' else 'Z';
mdio_rx <= enet_mdio_io;
enet_resetn_1v8_o <= '1';

end architecture;
