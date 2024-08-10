----------------------------------------------------------------------------------
-- Company: Digilent
-- Engineer: Arthur Brown
--
--
-- Create Date:    13:01:51 02/15/2013
-- Project Name:   pmodvga
-- Target Devices: arty
-- Tool versions:  2016.4
-- Additional Comments:
--
-- Copyright Digilent 2017
--
-- Modified by Alexander Cooke for use in a more advanced microblaze project for the Arty A7
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use work.vga_pkg.all;

    -- Uncomment the following library declaration if using
    -- arithmetic functions with Signed or Unsigned values
    use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity vga_ctrl is
    port (
        clk             : in    std_logic; -- Axi control interface clock
        rstn            : in    std_logic; -- Axi control interface reset

        refclk          : in    std_logic;

        resolution      : in    unsigned(2 downto 0);
        resolution_we   : in    std_logic;

        vga_hs_o        : out   std_logic;
        vga_vs_o        : out   std_logic;
        vga_r           : out   std_logic_vector(3 downto 0);
        vga_b           : out   std_logic_vector(3 downto 0);
        vga_g           : out   std_logic_vector(3 downto 0)
    );
end entity vga_ctrl;

architecture rtl of vga_ctrl is

    -- Sync Generation signals
    signal frame_width                       : natural;
    signal frame_height                      : natural;

    signal h_fp                              : natural;   -- H front porch width (pixels)
    signal h_pw                              : natural;   -- H sync pulse width (pixels)
    signal h_max                             : natural;   -- H total period (pixels)

    signal v_fp                              : natural;   -- V front porch width (lines)
    signal v_pw                              : natural;   -- V sync pulse width (lines)
    signal v_max                             : natural;   -- V total period (lines)

    signal h_pol                             : std_logic;
    signal v_pol                             : std_logic;

    signal resolution_index                  : integer;

    signal resolution_cdc                    : unsigned(resolution'range);
    signal resolution_r,    resolution_rr    : unsigned(resolution'range);
    signal resolution_we_cdc                 : std_logic;
    signal resolution_we_r, resolution_we_rr : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of resolution_r, resolution_we_r : signal is "true";

    signal vga_clk                           : std_logic;
    signal clk_running                       : std_logic;

    -- Moving Box constants
    constant BOX_WIDTH                       : natural := 20;
    constant BOX_CLK_DIV                     : natural := 1000000; -- MAX=(2^25 - 1)

    constant BOX_X_MAX                       : natural := (512 - BOX_WIDTH);
    constant BOX_Y_MAX                       : natural := (FRAME_HEIGHT - BOX_WIDTH);

    constant BOX_X_MIN                       : natural := 0;
    constant BOX_Y_MIN                       : natural := 256;

    constant BOX_X_INIT                      : std_logic_vector(11 downto 0) := x"000";
    constant BOX_Y_INIT                      : std_logic_vector(11 downto 0) := x"190"; -- 400

    signal active                            : std_logic;

    signal h_cntr_reg                        : std_logic_vector(11 downto 0) := (others => '0');
    signal v_cntr_reg                        : std_logic_vector(11 downto 0) := (others => '0');

    signal h_sync_reg                        : std_logic := not(H_POL);
    signal v_sync_reg                        : std_logic := not(V_POL);

    signal h_sync_dly_reg                    : std_logic := not(H_POL);
    signal v_sync_dly_reg                    : std_logic := not(V_POL);

    signal vga_red_reg                       : std_logic_vector(3 downto 0) := (others => '0');
    signal vga_green_reg                     : std_logic_vector(3 downto 0) := (others => '0');
    signal vga_blue_reg                      : std_logic_vector(3 downto 0) := (others => '0');

    signal vga_red                           : std_logic_vector(3 downto 0);
    signal vga_green                         : std_logic_vector(3 downto 0);
    signal vga_blue                          : std_logic_vector(3 downto 0);

    signal box_x_reg                         : std_logic_vector(11 downto 0) := BOX_X_INIT;
    signal box_x_dir                         : std_logic                     := '1';
    signal box_y_reg                         : std_logic_vector(11 downto 0) := BOX_Y_INIT;
    signal box_y_dir                         : std_logic                     := '1';
    signal box_cntr_reg                      : std_logic_vector(24 downto 0) := (others => '0');

    signal update_box                        : std_logic;
    signal pixel_in_box                      : std_logic;

begin

    resolution_index_cdc : process (clk, vga_clk) is
    begin

        if rising_edge(clk) then
            resolution_cdc    <= resolution;
            resolution_we_cdc <= resolution_we;
        end if;

        if rising_edge(vga_clk) then
            resolution_r  <= resolution_cdc;
            resolution_rr <= resolution_r;

            resolution_we_r  <= resolution_we_cdc;
            resolution_we_rr <= resolution_we_r;
        end if;

    end process resolution_index_cdc;

    ----------------------------------------------------
    -------         SET VGA PARAMS FROM CONFIG   -------
    ----------------------------------------------------
    resolution_index <= to_integer(resolution_rr);

    frame_width  <= RESOLUTION_ARRAY(resolution_index).frame_width;
    frame_height <= RESOLUTION_ARRAY(resolution_index).frame_height;
    h_fp         <= RESOLUTION_ARRAY(resolution_index).h_fp;
    h_pw         <= RESOLUTION_ARRAY(resolution_index).h_pw;
    h_max        <= RESOLUTION_ARRAY(resolution_index).h_max;
    v_fp         <= RESOLUTION_ARRAY(resolution_index).v_fp;
    v_pw         <= RESOLUTION_ARRAY(resolution_index).v_pw;
    v_max        <= RESOLUTION_ARRAY(resolution_index).v_max;
    h_pol        <= RESOLUTION_ARRAY(resolution_index).h_pol;
    v_pol        <= RESOLUTION_ARRAY(resolution_index).v_pol;

    ----------------------------------------------------
    -------         VGA CLK CONTROL              -------
    ----------------------------------------------------
    vga_clk_control_inst : entity work.vga_clk_control
        port map (
            clk               => clk,
            rstn              => rstn,
            refclk            => refclk,
            resolution_index  => resolution,
            resolution_change => resolution_we,
            vga_clk           => vga_clk,
            clk_running       => clk_running
        );

    ----------------------------------------------------
    -------         TEST PATTERN LOGIC           -------
    ----------------------------------------------------
    vga_red <= h_cntr_reg(5 downto 2) when (active = '1' and ((h_cntr_reg < 512 and v_cntr_reg < 256) and h_cntr_reg(8) = '1')) else
               (others => '1') when (active = '1' and ((h_cntr_reg < 512 and not(v_cntr_reg < 256)) and not(pixel_in_box = '1'))) else
               (others => '1') when (active = '1' and ((not(h_cntr_reg < 512) and (v_cntr_reg(8) = '1' and h_cntr_reg(3) = '1')) or
                                                          (not(h_cntr_reg < 512) and (v_cntr_reg(8) = '0' and v_cntr_reg(3) = '1')))) else
               (others => '0');

    vga_blue <= h_cntr_reg(5 downto 2) when (active = '1' and ((h_cntr_reg < 512 and v_cntr_reg < 256) and  h_cntr_reg(6) = '1')) else
                (others => '1') when (active = '1' and ((h_cntr_reg < 512 and not(v_cntr_reg < 256)) and not(pixel_in_box = '1'))) else
                (others => '1') when (active = '1' and ((not(h_cntr_reg < 512) and (v_cntr_reg(8) = '1' and h_cntr_reg(3) = '1')) or
                                                           (not(h_cntr_reg < 512) and (v_cntr_reg(8) = '0' and v_cntr_reg(3) = '1')))) else
                (others => '0');

    vga_green <= h_cntr_reg(5 downto 2) when (active = '1' and ((h_cntr_reg < 512 and v_cntr_reg < 256) and h_cntr_reg(7) = '1')) else
                 (others => '1') when (active = '1' and ((h_cntr_reg < 512 and not(v_cntr_reg < 256)) and not(pixel_in_box = '1'))) else
                 (others => '1') when (active = '1' and ((not(h_cntr_reg < 512) and (v_cntr_reg(8) = '1' and h_cntr_reg(3) = '1')) or
                                                            (not(h_cntr_reg < 512) and (v_cntr_reg(8) = '0' and v_cntr_reg(3) = '1')))) else
                 (others => '0');

    ------------------------------------------------------
    -------         MOVING BOX LOGIC                ------
    ------------------------------------------------------
    move_box : process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            if (update_box = '1') then
                if (box_x_dir = '1') then
                    box_x_reg <= box_x_reg + 1;
                else
                    box_x_reg <= box_x_reg - 1;
                end if;
                if (box_y_dir = '1') then
                    box_y_reg <= box_y_reg + 1;
                else
                    box_y_reg <= box_y_reg - 1;
                end if;
            end if;
        end if;

    end process move_box;

    display_box : process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            if (update_box = '1') then
                if ((box_x_dir = '1' and (box_x_reg >= BOX_X_MAX - 1)) or (box_x_dir = '0' and (box_x_reg <= BOX_X_MIN + 1))) then
                    box_x_dir <= not(box_x_dir);
                end if;
                if ((box_y_dir = '1' and (box_y_reg >= BOX_Y_MAX - 1)) or (box_y_dir = '0' and (box_y_reg <= BOX_Y_MIN + 1))) then
                    box_y_dir <= not(box_y_dir);
                end if;
            end if;
        end if;

    end process display_box;

    clk_div_box : process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            if (box_cntr_reg = (BOX_CLK_DIV - 1)) then
                box_cntr_reg <= (others => '0');
            else
                box_cntr_reg <= box_cntr_reg + 1;
            end if;
        end if;

    end process clk_div_box;

    update_box <= '1' when box_cntr_reg = (BOX_CLK_DIV - 1) else
                  '0';

    pixel_in_box <= '1' when (((h_cntr_reg >= box_x_reg) and (h_cntr_reg < (box_x_reg + BOX_WIDTH))) and
                                 ((v_cntr_reg >= box_y_reg) and (v_cntr_reg < (box_y_reg + BOX_WIDTH)))) else
                    '0';

    ------------------------------------------------------
    -------         SYNC GENERATION                 ------
    ------------------------------------------------------

    process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            if (h_cntr_reg = (h_max - 1)) then
                h_cntr_reg <= (others => '0');
            else
                h_cntr_reg <= h_cntr_reg + 1;
            end if;
        end if;

    end process;

    process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            if ((h_cntr_reg = (h_max - 1)) and (v_cntr_reg = (v_max - 1))) then
                v_cntr_reg <= (others => '0');
            elsif (h_cntr_reg = (h_max - 1)) then
                v_cntr_reg <= v_cntr_reg + 1;
            end if;
        end if;

    end process;

    process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            if ((h_cntr_reg >= (h_fp + frame_width - 1)) and (h_cntr_reg < (h_fp + frame_width + h_pw - 1))) then
                h_sync_reg <= h_pol;
            else
                h_sync_reg <= not(h_pol);
            end if;
        end if;

    end process;

    process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            if ((v_cntr_reg >= (v_fp + frame_height - 1)) and (v_cntr_reg < (v_fp + frame_height + v_pw - 1))) then
                v_sync_reg <= v_pol;
            else
                v_sync_reg <= not(v_pol);
            end if;
        end if;

    end process;

    active <= '1' when ((h_cntr_reg < frame_width) and (v_cntr_reg < frame_height)) else
              '0';

    process (vga_clk) is
    begin

        if (rising_edge(vga_clk)) then
            v_sync_dly_reg <= v_sync_reg;
            h_sync_dly_reg <= h_sync_reg;
            vga_red_reg    <= vga_red;
            vga_green_reg  <= vga_green;
            vga_blue_reg   <= vga_blue;
        end if;

    end process;

    vga_hs_o <= h_sync_dly_reg when clk_running = '1' or rstn = '1' else
                '0';
    vga_vs_o <= v_sync_dly_reg when clk_running = '1' or rstn = '1' else
                '0';
    vga_r    <= vga_red_reg when clk_running = '1' or rstn = '1' else
                (others => '0');
    vga_g    <= vga_green_reg when clk_running = '1' or rstn = '1' else
                (others => '0');
    vga_b    <= vga_blue_reg when clk_running = '1' or rstn = '1' else
                (others => '0');

end architecture rtl;
