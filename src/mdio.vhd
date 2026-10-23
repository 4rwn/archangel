library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mdio is
    port (
        clk100M_i : in std_logic;
        clk2M5_rise_en_i : in std_logic;
        clk2M5_fall_en_i : in std_logic;
        
        start_i : in std_logic;

        mdio_tx_en_o : out std_logic;
        mdio_tx_o : out std_logic;
        mdio_rx_i : in std_logic
    );
end entity;

architecture rtl of mdio is
    type state_t is (IDLE, PREAMBLE, START_FRAME, OPCODE, PHY_ADDR, REG_ADDR, TURNAROUND, DATA);
    signal state : state_t := IDLE;

    signal mdio_tx_en : std_logic := '0';
    signal mdio_tx : std_logic := '0';
    signal mdio_rx : std_logic := '0';

    signal reg_data : std_logic_vector(15 downto 0) := (others => '0');
begin

process (clk100M_i)
    variable count : unsigned(4 downto 0) := (others => '0');
begin
    if rising_edge(clk100M_i) then
        if (clk2M5_fall_en_i = '1') then
            case state is
                when IDLE =>
                    if start_i = '1' then
                        state <= PREAMBLE;

                        mdio_tx_en <= '1';
                        mdio_tx <= '1';

                        count := (others => '0');
                    end if;
                when PREAMBLE =>
                    count := count + 1;

                    if count = 0 then
                        state <= START_FRAME;

                        mdio_tx <= '0';
                    end if;
                when START_FRAME =>
                    mdio_tx <= '1';
                    state <= OPCODE;
                    count := (others => '0');
                when OPCODE =>
                    if count = 0 then
                        mdio_tx <= '1';
                        count := count + 1;
                    else
                        mdio_tx <= '0';
                        state <= PHY_ADDR;
                        count := (others => '0');
                    end if;
                when PHY_ADDR =>
                    if count = 5 then
                        state <= REG_ADDR;
                        count := (others => '0');
                    else
                        count := count + 1;
                    end if;
                when REG_ADDR =>
                    if count = 5 then
                        state <= TURNAROUND;
                        mdio_tx <= '0';
                        count := (others => '0');
                    else
                        count := count + 1;
                    end if;
                when TURNAROUND =>
                    if count = 1 then
                        state <= DATA;
                        count := (others => '0');
                    else
                        count := count + 1;
                    end if;
                when DATA =>
                    if count = 16 then
                        state <= IDLE;
                        count := (others => '0');
                    else
                        reg_data(15 - to_integer(count)) <= mdio_tx;
                        count := count + 1;
                    end if;
                when others =>
                    null;
            end case;
        end if;
    end if;
end process;

mdio_tx_en_o <= mdio_tx_en;
mdio_tx_o <= mdio_tx;
mdio_rx <= mdio_rx_i;

end architecture;