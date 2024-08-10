library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package vga_pkg is

    constant RESOLUTION_MAX : natural := 4;

    type resolution_t is record
        frame_width  : natural;
        frame_height : natural;

        h_fp  : natural; -- H front porch width (pixels)
        h_pw  : natural; -- H sync pulse width (pixels)
        h_max : natural; -- H total period (pixels)

        v_fp  : natural; -- V front porch width (lines)
        v_pw  : natural; -- V sync pulse width (lines)
        v_max : natural; -- V total period (lines)

        h_pol : std_logic;
        v_pol : std_logic;

        -- MMCM values here are multiplied by 1000. Must be divided again by 1000 to be entered into MMCM
        mmcm_in_mult        : natural;
        mmcm_in_mult_frac   : natural;
        mmcm_in_div         : natural;
        mmcm_out0_div       : natural;
        mmcm_out0_div_frac  : natural;
    end record resolution_t;

    type clk_wiz_reg_arr_t is array (0 to 1) of std_logic_vector(31 downto 0);

    type resolution_array_t is array (natural range<>) of resolution_t;

    -- ***640x480@60Hz***--  Requires 25 MHz clock
    constant R640X480 : resolution_t :=
    (
        frame_width        => 640,
        frame_height       => 480,
        h_fp               => 16,
        h_pw               => 96,
        h_max              => 800,
        v_fp               => 10,
        v_pw               => 2,
        v_max              => 525,
        h_pol              => '0',
        v_pol              => '0',
        mmcm_in_mult       => 9,
        mmcm_in_mult_frac  => 125,
        mmcm_in_div        => 1,
        mmcm_out0_div      => 36,
        mmcm_out0_div_frac => 500
    );

    -- ***800x600@60Hz***--  Requires 40 MHz clock
    constant R800X600 : resolution_t :=
    (
        frame_width        => 800,
        frame_height       => 600,
        h_fp               => 40,
        h_pw               => 128,
        h_max              => 1056,
        v_fp               => 1,
        v_pw               => 4,
        v_max              => 628,
        h_pol              => '1',
        v_pol              => '1',
        mmcm_in_mult       => 10,
        mmcm_in_mult_frac  => 0,
        mmcm_in_div        => 1,
        mmcm_out0_div      => 25,
        mmcm_out0_div_frac => 0
    );

    -- ***1280x720@60Hz***-- Requires 74.25 MHz clock
    constant R1280X720 : resolution_t :=
    (
        frame_width        => 1280,
        frame_height       => 720,
        h_fp               => 110,
        h_pw               => 40,
        h_max              => 1650,
        v_fp               => 5,
        v_pw               => 5,
        v_max              => 750,
        h_pol              => '1',
        v_pol              => '1',
        mmcm_in_mult       => 37,
        mmcm_in_mult_frac  => 125,
        mmcm_in_div        => 4,
        mmcm_out0_div      => 12,
        mmcm_out0_div_frac => 500
    );

    -- ***1280x1024@60Hz***-- Requires 108 MHz clock
    constant R1280X1024 : resolution_t :=
    (
        frame_width        => 1280,
        frame_height       => 1024,
        h_fp               => 48,
        h_pw               => 112,
        h_max              => 1688,
        v_fp               => 1,
        v_pw               => 3,
        v_max              => 1066,
        h_pol              => '1',
        v_pol              => '1',
        mmcm_in_mult       => 10,
        mmcm_in_mult_frac  => 125,
        mmcm_in_div        => 1,
        mmcm_out0_div      => 9,
        mmcm_out0_div_frac => 375
    );

    -- ***1920x1080@60Hz***-- Requires 148.5 MHz
    constant R1920X1080 : resolution_t :=
    (
        frame_width        => 1920,
        frame_height       => 1080,
        h_fp               => 88,
        h_pw               => 44,
        h_max              => 2200,
        v_fp               => 4,
        v_pw               => 5,
        v_max              => 1125,
        h_pol              => '1',
        v_pol              => '1',
        mmcm_in_mult       => 37,
        mmcm_in_mult_frac  => 125,
        mmcm_in_div        => 4,
        mmcm_out0_div      => 6,
        mmcm_out0_div_frac => 250
    );

    constant RESOLUTION_ARRAY : resolution_array_t := (R640X480, R800X600, R1280X720, R1280X1024, R1920X1080);

    function get_vga_clk_regs (
        resolution_index : unsigned
    ) return clk_wiz_reg_arr_t;

end package vga_pkg;

package body vga_pkg is

    function get_vga_clk_regs (
        resolution_index : unsigned
    ) return clk_wiz_reg_arr_t is

        variable resolution : resolution_t;

        variable reg0_data : std_logic_vector(31 downto 0);
        variable reg2_data : std_logic_vector(31 downto 0);

        variable clk_wiz_regs : clk_wiz_reg_arr_t;

    begin

        resolution := RESOLUTION_ARRAY(to_integer(resolution_index));

        -- divclk_divide
        clk_wiz_regs(0)(7 downto 0) := std_logic_vector(to_unsigned(resolution.mmcm_in_div, 8));
        -- clkfbout_mult
        clk_wiz_regs(0)(15 downto 8) := std_logic_vector(to_unsigned(resolution.mmcm_in_mult, 8));
        -- clkfbout_fract
        clk_wiz_regs(0)(25 downto 16) := std_logic_vector(to_unsigned(resolution.mmcm_in_mult_frac, 10));
        clk_wiz_regs(0)(31 downto 26) := (others => '0');
        -- clkout0_div
        clk_wiz_regs(1)(7 downto 0)   := std_logic_vector(to_unsigned(resolution.mmcm_out0_div, 8));
        -- clkout0_div_fract
        clk_wiz_regs(1)(17 downto 8)   := std_logic_vector(to_unsigned(resolution.mmcm_out0_div_frac, 10));
        clk_wiz_regs(1)(31 downto 18)  := (others => '0');

        return clk_wiz_regs;

    end function;

end package body vga_pkg;
