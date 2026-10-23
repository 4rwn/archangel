library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    port (
        clk100M_i : in std_logic;
        clk2M5_rise_en_i : in std_logic;

        secs_o : out std_logic_vector(15 downto 0)
    );
end entity;

architecture rtl of timer is
    signal count : unsigned(11 downto 0) := (others => '0');
    signal msecs : unsigned(9 downto 0) := (others => '0');
    signal secs : unsigned(15 downto 0) := (others => '0');

    attribute noprune : boolean;
    attribute noprune of count : signal is true;
    attribute noprune of msecs : signal is true;
    attribute noprune of secs : signal is true;
begin

process (clk100M_i)
begin
    if rising_edge(clk100M_i) then
        if clk2M5_rise_en_i = '1' then
            count <= count + 1;
            if count = 2499 then
                count <= (others => '0');

                msecs <= msecs + 1;
                if msecs = 999 then
                    msecs <= (others => '0');

                    secs <= secs + 1;
                end if;
            end if;
        end if;
    end if;
end process;

secs_o <= std_logic_vector(secs);

end architecture;