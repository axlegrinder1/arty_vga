library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity mmcm_drp is
    port (
        saddr    : in    std_logic_vector(6 downto 0);
        sen      : in    std_logic;
        srdy     : out   std_logic;
        sclk     : in    std_logic;
        srst     : in    std_logic;

        dwe      : out   std_logic;
        den      : out   std_logic;
        daddr    : out   std_logic_vector(6 downto 0);
        di       : out   std_logic_vector(15 downto 0);
        do       : in    std_logic_vector(15 downto 0);
        drdy     : in    std_logic;
        dclk     : out   std_logic;
        locked   : in    std_logic;
        rst_mmcm : out   std_logic
    );
end entity mmcm_drp;

architecture rtl of mmcm_drp is

    type drp_state_t is (restart, wait_lock, wait_sen, address, wait_a_drdy, bitmask, bitset, write, wait_drdy);

    signal drp_state      : drp_state_t;
    signal drp_next_state : drp_state_t;

begin

    process (sclk) is
    begin

        case drp_state is

            when restart =>
                if srst = '0' then
                    drp_next_state <= wait_lock;
                end if;
            when wait_lock =>

            when wait_sen =>

            when address =>

            when wait_a_drdy =>

            when bitmask =>

            when bitset =>

            when write =>

            when wait_drdy =>

            when others =>

                null;

        end case;

    end process;

    process (sclk) is
    begin

        if rising_edge(sclk) then
            drp_state <= drp_next_state;
        end if;

    end process;

end architecture rtl;
