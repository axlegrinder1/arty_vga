library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity button_debounce_sync is
    generic (
        DEPTH       : natural := 16;
        WIDTH       : natural := 1;
        OUTPUT_MODE : string  := "pulse";
        ACTIVE_STATE : std_logic := '1'
    );
    port (
        clk        : in    std_logic;

        input      : in    std_logic_vector(WIDTH - 1 downto 0);
        output     : out   std_logic_vector(WIDTH - 1 downto 0)
    );
end entity button_debounce_sync;

architecture rtl of button_debounce_sync is

    type count_array_t is array (WIDTH - 1 downto 0) of unsigned(DEPTH - 1 downto 0);

    signal counter      : count_array_t := (others => (others => '0'));

    type state_t is (wait_push, hold);

    type state_arr is array (WIDTH - 1 downto 0) of state_t;

    signal state        : state_arr := (others => (wait_push));

    signal state_change : std_logic_vector(WIDTH - 1 downto 0);

begin

    parallel_debounce : for i in (WIDTH - 1) downto 0 generate

        process (clk) is
        begin

            -- Default values
            state_change(i) <= NOT ACTIVE_STATE;

            if rising_edge(clk) then

                case state(i) is

                    when wait_push =>

                        if (input(i) = ACTIVE_STATE) then
                            counter(i)      <= (others => '1');
                            state_change(i) <= ACTIVE_STATE;
                            state(i)        <= hold;
                        end if;

                    when hold =>

                        if (input(i) = ACTIVE_STATE) then
                            counter(i) <= (others => '1');
                        else
                            counter(i) <= counter(i) - 1;
                        end if;

                        if (counter(i) = 0) then
                            state(i) <= wait_push;
                        end if;

                    when others =>

                        state(i) <= wait_push;

                end case;

            end if;

        end process;

        output_type : if (OUTPUT_MODE = "pulse") generate
            output(i) <= state_change(i);
        elsif (OUTPUT_MODE = "hold") generate
            output(i) <= ACTIVE_STATE when (state(i) = hold) else
                         NOT ACTIVE_STATE;
        else generate
            assert TRUE
                report "Invalid output_mode";
        end generate output_type;

    end generate parallel_debounce;

end architecture rtl;
