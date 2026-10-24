library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_archangel is
end entity;

architecture sim of tb_archangel is
    constant CLK_PERIOD : time := 10 ns;
    constant PHY_DELAY : time := 60 ns;
    type register_array_t is array (0 to 3) of std_logic_vector(15 downto 0);
    constant REGISTERS : register_array_t := (x"1040", x"7949", x"0283", x"BC30");

    signal clk : std_logic := '0';
    signal mdc : std_logic := '0';
    signal rise_en, fall_en : std_logic := '0';
    signal start : std_logic := '0';
    signal reg_addr : std_logic_vector(4 downto 0) := (others => '0');
    signal phy_addr : std_logic_vector(4 downto 0) := (others => '0');
    signal done, err, tx_en, tx : std_logic;
    signal data : std_logic_vector(15 downto 0);
    signal mdio : std_logic;
    signal phy_drive : std_logic := 'Z';
    signal responses : natural := 0;
begin
    clk <= not clk after CLK_PERIOD / 2;

    -- Exercise MDIO directly to avoid the top-level 10.74 second startup.
    dut : entity work.mdio
    port map (
        clk100M_i => clk,
        clk2M5_rise_en_i => rise_en,
        clk2M5_fall_en_i => fall_en,
        start_i => start,
        reg_addr_i => '1',
        phy_addr_i => phy_addr,
        reg_addr => reg_addr,
        data_i => (others => '0'),
        done_o => done,
        data_o => data,
        err_o => err,
        mdio_tx_en_o => tx_en,
        mdio_tx_o => tx,
        mdio_rx_i => mdio
    );

    -- Both sides only pull low; the resistor supplies the high level.
    mdio <= 'H';
    mdio <= '0' when tx_en = '1' and tx = '0' else 'Z';
    mdio <= phy_drive;

    process (clk)
        variable divider : natural range 0 to 19 := 0;
    begin
        if rising_edge(clk) then
            rise_en <= '0';
            fall_en <= '0';
            if divider = 19 then
                divider := 0;
                mdc <= not mdc;
                if mdc = '0' then
                    rise_en <= '1';
                else
                    fall_en <= '1';
                end if;
            else
                divider := divider + 1;
            end if;
        end if;
    end process;

    -- PHY model: recognize a complete Clause 22 read header, acknowledge,
    -- then launch register data after rising MDC, MSB first.
    process
        variable preamble_bits : natural := 0;
        variable header : std_logic_vector(13 downto 0);
        variable address : natural;
        variable response : std_logic_vector(15 downto 0);
    begin
        loop
            wait until rising_edge(mdc);
            if to_x01(mdio) = '1' then
                preamble_bits := preamble_bits + 1;
            else
                assert to_x01(mdio) = '0' and preamble_bits >= 32
                    report "Invalid start bit or short preamble" severity failure;
                header(13) := '0';
                for bit_index in 12 downto 0 loop
                    wait until rising_edge(mdc);
                    header(bit_index) := to_x01(mdio);
                end loop;
                assert header(13 downto 12) = "01"
                    report "Incorrect start field; header = " & to_string(header) severity failure;
                assert header(11 downto 10) = "10"
                    report "Expected read opcode" severity failure;
                address := to_integer(unsigned(header(4 downto 0)));
                assert address <= 3 report "Unexpected register address" severity failure;
                -- Use PHY addresses 0, 5, 10, and 15 to verify the address
                -- field independently of the register field and its bit order.
                assert unsigned(header(9 downto 5)) = address * 5
                    report "Incorrect PHY address" severity failure;
                response := REGISTERS(address);

                -- First turnaround slot: host must release the line.
                wait until rising_edge(mdc);
                assert tx_en = '0' and to_x01(mdio) = '1'
                    report "Host did not release first turnaround slot" severity failure;
                -- Launch ACK, valid for the next rising edge.
                phy_drive <= '0' after PHY_DELAY;
                wait until rising_edge(mdc);
                assert to_x01(mdio) = '0'
                    report "Missing turnaround acknowledgement" severity failure;

                for bit_index in 15 downto 0 loop
                    if response(bit_index) = '0' then
                        phy_drive <= '0' after PHY_DELAY;
                    else
                        phy_drive <= 'Z' after PHY_DELAY;
                    end if;
                    wait until rising_edge(mdc);
                    assert tx_en = '0'
                        report "Host drove MDIO during PHY response" severity failure;
                    assert to_x01(mdio) = response(bit_index)
                        report "Incorrect response on MDIO" severity failure;
                end loop;
                phy_drive <= 'Z' after PHY_DELAY;
                responses <= responses + 1;
                preamble_bits := 0;
            end if;
        end loop;
    end process;

    -- Issue short requests away from MDC falling enables and check results.
    process
    begin
        wait for 225 ns;
        for address in 0 to 3 loop
            wait until falling_edge(clk);
            reg_addr <= std_logic_vector(to_unsigned(address, 5));
            phy_addr <= std_logic_vector(to_unsigned(address * 5, 5));
            start <= '1';
            wait until falling_edge(clk);
            start <= '0';
            wait until done = '1';
            assert err = '0' report "Read completed with error" severity failure;
            assert data = REGISTERS(address)
                report "Incorrect captured data for register " & integer'image(address)
                severity failure;
            report "Read register " & integer'image(address) & " = 0x" & to_hstring(data);
            wait until rising_edge(clk);
            wait for 1 ns;
            assert done = '0' report "Done is not a one-cycle pulse" severity failure;
            wait for 1 us;
        end loop;
        assert responses = 4 report "Missing PHY responses" severity failure;
        report "All four MDIO reads passed";
        std.env.stop;
        wait;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            assert err /= '1' report "MDIO controller reported an error" severity failure;
        end if;
    end process;

    process
    begin
        wait for 150 us;
        assert false report "MDIO test timed out" severity failure;
    end process;
end architecture;
