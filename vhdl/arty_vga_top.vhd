library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.vga_pkg.all;
    use work.ver_pkg.all;

library unisim;
    use unisim.vcomponents.all;

entity arty_vga_top is
    port (
        -- Ref clock and reset
        clk100mhz   : in    std_logic;
        ck_rstn     : in    std_logic_vector(0 downto 0);
        -- button and switch inputs
        sw          : in    std_logic_vector(3 downto 0);
        btn         : in    std_logic_vector(3 downto 0);
        -- Single colour LEDs
        led         : out   std_logic_vector(3 downto 0);
        -- RGB LEDs
        led0_b      : out   std_logic;
        led0_g      : out   std_logic;
        led0_r      : out   std_logic;
        led1_b      : out   std_logic;
        led1_g      : out   std_logic;
        led1_r      : out   std_logic;
        led2_b      : out   std_logic;
        led2_g      : out   std_logic;
        led2_r      : out   std_logic;
        led3_b      : out   std_logic;
        led3_g      : out   std_logic;
        led3_r      : out   std_logic;
        -- Outputs to VGA ports
        vga_r       : out   std_logic_vector(3 downto 0);
        vga_g       : out   std_logic_vector(3 downto 0);
        vga_b       : out   std_logic_vector(3 downto 0);
        vga_hs_o    : out   std_logic;
        vga_vs_o    : out   std_logic
    );
end entity arty_vga_top;

architecture rtl of arty_vga_top is

    signal clk            : std_logic;
    signal rstn           : std_logic;

    -- Debounced button input
    signal btn_clean      : std_logic_vector(btn'range);

    signal resolution     : unsigned(2 downto 0);
    signal resolution_we  : std_logic;

begin

    -- Reset and clock input buffers
    reset_debounce : entity work.button_debounce_sync
        generic map (
            DEPTH        => 8,
            OUTPUT_MODE  => "hold",
            ACTIVE_STATE => '0'
        )
        port map (
            clk       => clk,
            input     => ck_rstn,
            output(0) => rstn
        );

    master_clock_bufg_inst : component bufg
        port map (
            o => clk,      -- 1-bit output: Clock output
            i => clk100mhz -- 1-bit input: Clock input
        );

    pushbutton_debounce : entity work.button_debounce_sync
        generic map (
            WIDTH => btn'length
        )
        port map (
            clk    => clk,
            input  => btn,
            output => btn_clean
        );

    vga_ctrl_inst : entity work.vga_ctrl
        port map (
            clk           => clk,
            rstn          => rstn,
            refclk        => clk100mhz,
            resolution    => resolution,
            resolution_we => resolution_we,
            vga_hs_o      => vga_hs_o,
            vga_vs_o      => vga_vs_o,
            vga_r         => vga_r,
            vga_b         => vga_b,
            vga_g         => vga_g
        );

    toggle_resolution : process (clk) is
    begin

        if rising_edge(clk) then
            if (rstn = '0') then
                resolution <= (others => '0');
            else
                resolution_we <= '0';
                if (btn_clean(0) = '1') then
                    if (resolution = RESOLUTION_MAX) then
                        resolution <= (others => '0');
                    else
                        resolution <= resolution + 1;
                    end if;
                    resolution_we <= '1';
                elsif (btn_clean(1) = '1') then
                    if (resolution = 0) then
                        resolution <= to_unsigned(RESOLUTION_MAX, resolution'length);
                    else
                        resolution <= resolution - 1;
                    end if;
                    resolution_we <= '1';
                end if;
            end if;
        end if;

    end process toggle_resolution;

end architecture rtl;
