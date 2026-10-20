library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
    port (
        clk   : in std_logic;
        reset : in std_logic
    );
end entity;

architecture rtl of timer is
    signal count : unsigned(6 downto 0) := (others => '0');
    signal usecs : unsigned(9 downto 0) := (others => '0');
    signal msecs : unsigned(9 downto 0) := (others => '0');
    signal secs : unsigned(31 downto 0) := (others => '0');
begin

process (clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            count <= (others => '0');
            usecs <= (others => '0');
            msecs <= (others => '0');
            secs <= (others => '0');
        else
            count <= count + 1;
            if count = 99 then
                count <= (others => '0');

                usecs <= usecs + 1;
                if usecs = 999 then
                    usecs <= (others => '0');

                    msecs <= msecs + 1;
                    if msecs = 999 then
                        msecs <= (others => '0');

                        secs <= secs + 1;
                    end if;
                end if;
            end if;
        end if;
    end if;
end process;

end architecture;