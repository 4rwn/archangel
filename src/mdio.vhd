library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mdio is
    port (
        clk100M_i : in std_logic;
        clk2M5_rise_en_i : in std_logic;
        clk2M5_fall_en_i : in std_logic;
        
        start_i : in std_logic;
        rd_nwr_i : in std_logic;
        reg_addr : in std_logic_vector(4 downto 0);
        data_i : in std_logic_vector(15 downto 0);

        done_o : out std_logic;
        data_o : out std_logic_vector(15 downto 0);
        err_o : out std_logic;

        mdio_tx_en_o : out std_logic;
        mdio_tx_o : out std_logic;
        mdio_rx_i : in std_logic
    );
end entity;

architecture rtl of mdio is
    type state_t is (S_IDLE, S_SEND, S_RECV, S_DONE);
    signal state : state_t := S_IDLE;

    signal done : std_logic := '0';
    signal data : std_logic_vector(15 downto 0) := (others => '0');
    signal err : std_logic := '0';
    signal mdio_tx_en : std_logic := '0';
    signal mdio_tx : std_logic := '0';

    signal cmd : std_logic_vector(0 to 63) := (others => '0');
    signal idx : unsigned(5 downto 0) := (others => '0');
begin

process (clk100M_i)
    variable opcode : std_logic_vector(1 downto 0) := (others => '0');
begin
    if rising_edge(clk100M_i) then
        err <= '0';
        done <= '0';

        if state = S_IDLE then
            if start_i = '1' then
                if rd_nwr_i = '1' then
                    opcode := "10";
                else 
                    opcode := "01";
                end if;

                cmd <= x"FFFFFFFF" & "01" & opcode & "00000" & reg_addr & "10" & data_i;

                state <= S_SEND;
                idx <= (others => '0');
            end if;
        else
            if clk2M5_fall_en_i = '1' then
                idx <= idx + 1;
                mdio_tx_en <= '0';
                case state is
                    when S_SEND =>
                        mdio_tx_en <= '1';
                        mdio_tx <= cmd(to_integer(idx));

                        if opcode = "10" and idx = 45 then
                            state <= S_RECV;
                        elsif opcode = "01" and idx = 63 then
                            state <= S_DONE;
                        end if;

                    when S_RECV =>
                        if idx = 47 and to_x01(mdio_rx_i) /= '0' then
                            err <= '1';
                            state <= S_IDLE;
                        elsif idx > 47 then
                            data(63 - to_integer(idx)) <= to_x01(mdio_rx_i);

                            if idx = 63 then
                                state <= S_DONE;
                            end if;
                        end if;

                    when S_DONE =>
                        done <= '1';
                        state <= S_IDLE;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end if;
end process;

done_o <= done;
data_o <= data;
err_o <= err;
mdio_tx_en_o <= mdio_tx_en;
mdio_tx_o <= mdio_tx;

end architecture;
