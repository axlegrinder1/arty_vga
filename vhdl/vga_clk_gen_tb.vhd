library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity vga_clk_gen_tb is
end entity vga_clk_gen_tb;

architecture rtl of vga_clk_gen_tb is

    signal axi_clk           : std_logic;

    signal rstn              : std_logic                     := '0';
    signal refclk            : std_logic                     := '0';
    signal resolution_index  : std_logic_vector(2 downto 0)  := (others => '0');
    signal resolution_change : std_logic                     := '0';
    signal vga_clk           : std_logic;
    signal clk_running       : std_logic;

begin

    resolution_change_proc : process is
    begin

        wait on rstn until rstn = '1';

        wait for 20 us;
        wait on axi_clk until axi_clk = '1';
        resolution_index  <= "001";
        resolution_change <= '1';

        wait on axi_clk until axi_clk = '1';
        resolution_change <= '0';

        wait for 20 us;

        wait on axi_clk until axi_clk = '1';
        resolution_index  <= "010";
        resolution_change <= '1';

        wait on axi_clk until axi_clk = '1';
        resolution_change <= '0';

        wait for 20 us;

    end process resolution_change_proc;

    axi_clk <= not axi_clk after 8.33333 ns;
    refclk  <= not refclk after 10 ns;

    rstn    <= '1' after 100 ns;

    vga_clk_gen_inst : entity work.vga_clk_control
        port map (
            axi_clk           => axi_clk,
            rstn              => rstn,
            refclk            => refclk,
            resolution_index  => resolution_index,
            resolution_change => resolution_change,
            vga_clk           => vga_clk,
            clk_running       => clk_running
        );

end architecture rtl;
