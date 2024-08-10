library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use work.vga_pkg.all;
    use work.axi4_lite_pkg.all;

-- library unisim;
--     use unisim.vcomponents.all;

entity vga_clk_control is
    port (
        clk               : in    std_logic;
        rstn              : in    std_logic;

        refclk            : in    std_logic; -- Main board reference clock to be manipulated by mmcm

        resolution_index  : in    unsigned(2 downto 0);
        resolution_change : in    std_logic;

        vga_clk           : out   std_logic;
        clk_running       : out   std_logic
    );
end entity vga_clk_control;

architecture rtl of vga_clk_control is

    type clk_reconfig_state_t is (reset, running, reg0_write, reg0_wait, reg1_write, reg1_wait, activate_reconfig_write, activate_reconfig_wait, wait_lock);

    signal clk_reconfig_state, clk_reconfig_state_next              : clk_reconfig_state_t;

    signal axi_in                                                   : axi4_lite_slave_in_t;
    signal axi_out                                                  : axi4_lite_slave_out_t;

    signal locked                                                   : std_logic;

    signal vga_clk_bufg                                             : std_logic;
    signal output_en                                                : std_logic;

    signal output_en_cdc                                            : std_logic;
    signal output_en_vgaclk,   output_en_vgaclk_r                   : std_logic;

    attribute ASYNC_REG : string;
    attribute ASYNC_REG of output_en_vgaclk_r : signal is "true";

    signal mmcm_pwrdwn                                              : std_logic;

    signal clkregs                                                  : clk_wiz_reg_arr_t;

    attribute MARK_DEBUG : string;

    attribute MARK_DEBUG of
        axi_in,
        axi_out,
        clk_reconfig_state,
        locked,
        resolution_index,
        resolution_change
    : signal is "true";

begin

    clk_reconfig_state_machine : process (all) is
    begin

        -- default states

        output_en   <= '0';
        clk_running <= '0';

        axi_in.s_axi_awvalid <= '0';
        axi_in.s_axi_awaddr  <= (others => '0');

        axi_in.s_axi_wvalid <= '0';
        axi_in.s_axi_wstrb  <= (others => '0');
        axi_in.s_axi_wdata  <= (others => '0');

        case clk_reconfig_state is

            when reset =>

                clk_reconfig_state_next <= reset;

                if (rstn = '1') then
                    clk_reconfig_state_next <= reg0_write;
                end if;

            when running =>

                clk_reconfig_state_next <= running;

                output_en   <= '1';
                clk_running <= '1';

                if (resolution_change = '1') then
                    clk_reconfig_state_next <= reg0_write;
                end if;

            when reg0_write =>

                clk_reconfig_state_next <= reg0_write;

                axi_in.s_axi_awvalid <= '1';
                axi_in.s_axi_awaddr  <= 11X"200";

                axi_in.s_axi_wvalid <= '1';
                axi_in.s_axi_wdata  <= clkregs(0);
                axi_in.s_axi_wstrb  <= "1111";

                if (axi_out.s_axi_awready = '1' and axi_out.s_axi_wready = '1') then
                    clk_reconfig_state_next <= reg0_wait;
                end if;

            when reg0_wait =>

                clk_reconfig_state_next <= reg0_wait;

                axi_in.s_axi_awaddr  <= 11X"200";
                -- axi_in.s_axi_wvalid <= '1';
                -- axi_in.s_axi_wdata  <= clkregs(0);
                -- axi_in.s_axi_wstrb  <= "1111";

                if (axi_out.s_axi_bvalid = '1') then
                    clk_reconfig_state_next <= reg1_write;
                end if;

            when reg1_write =>

                clk_reconfig_state_next <= reg1_write;

                axi_in.s_axi_awvalid <= '1';
                axi_in.s_axi_awaddr  <= 11X"208";

                axi_in.s_axi_wvalid <= '1';
                axi_in.s_axi_wdata  <= clkregs(1);
                axi_in.s_axi_wstrb  <= "1111";

                if (axi_out.s_axi_awready = '1' and axi_out.s_axi_wready = '1') then
                    clk_reconfig_state_next <= reg1_wait;
                end if;

            when reg1_wait =>

                clk_reconfig_state_next <= reg1_wait;

                -- axi_in.s_axi_wvalid <= '1';
                -- axi_in.s_axi_wdata  <= clkregs(1);
                -- axi_in.s_axi_wstrb  <= "1111";

                axi_in.s_axi_awaddr  <= 11X"208";

                if (axi_out.s_axi_bvalid = '1') then
                    clk_reconfig_state_next <= activate_reconfig_write;
                end if;

            when activate_reconfig_write =>

                clk_reconfig_state_next <= activate_reconfig_write;

                axi_in.s_axi_awvalid <= '1';
                axi_in.s_axi_awaddr  <= 11X"25C";

                axi_in.s_axi_wvalid <= '1';
                axi_in.s_axi_wdata  <= 32X"3";
                axi_in.s_axi_wstrb  <= "1111";

                if (axi_out.s_axi_awready = '1' and axi_out.s_axi_wready = '1') then
                    clk_reconfig_state_next <= activate_reconfig_wait;
                end if;

            when activate_reconfig_wait =>

                clk_reconfig_state_next <= activate_reconfig_wait;

                axi_in.s_axi_awaddr  <= 11X"25C";
                -- axi_in.s_axi_wvalid <= '1';
                -- axi_in.s_axi_wdata  <= 32X"3";
                -- axi_in.s_axi_wstrb  <= "1111";

                if (axi_out.s_axi_bvalid = '1') then
                    clk_reconfig_state_next <= wait_lock;
                end if;

            when wait_lock =>

                clk_reconfig_state_next <= wait_lock;

                if (locked = '1') then
                    clk_reconfig_state_next <= running;
                end if;

            when others =>

                clk_reconfig_state_next <= reset;

        end case;

    end process clk_reconfig_state_machine;

    clk_reconfig_reg : process (clk) is
    begin

        if rising_edge(clk) then
            if (rstn = '0') then
                clk_reconfig_state <= reset;
            else
                clk_reconfig_state <= clk_reconfig_state_next;

                clkregs                 <= get_vga_clk_regs(resolution_index);
            end if;
        end if;

    end process clk_reconfig_reg;

    output_en_cdc_proc : process (clk, vga_clk_bufg) is
    begin

        if rising_edge(clk) then
            output_en_cdc <= output_en;
        end if;

    -- if rising_edge(vga_clk_bufg) then
    --     output_en_vgaclk   <= output_en_cdc;
    --     output_en_vgaclk_r <= output_en_vgaclk;
    -- end if;

    end process output_en_cdc_proc;

    bufgce_inst : component bufg     -- ce
        port map (
            o  => vga_clk,           -- 1-bit output: Clock output
            -- ce => output_en_rr,      -- 1-bit input: Clock enable input for I0
            i  => vga_clk_bufg       -- 1-bit input: Primary clock
        );

    ----------------------------------------------------
    -------         CLOCK GENERATOR              -------
    ----------------------------------------------------
    vga_clk_wiz_i : entity work.vga_clk_wiz
        port map (
            s_axi_aclk                => axi_in.s_axi_aclk,
            s_axi_aresetn             => axi_in.s_axi_aresetn,

            s_axi_awaddr              => axi_in.s_axi_awaddr,
            s_axi_awvalid             => axi_in.s_axi_awvalid,
            s_axi_awready             => axi_out.s_axi_awready,
            s_axi_wdata               => axi_in.s_axi_wdata,
            s_axi_wstrb               => axi_in.s_axi_wstrb,
            s_axi_wvalid              => axi_in.s_axi_wvalid,
            s_axi_wready              => axi_out.s_axi_wready,
            s_axi_bresp               => axi_out.s_axi_bresp,
            s_axi_bvalid              => axi_out.s_axi_bvalid,
            s_axi_bready              => '1', -- axi_in.s_axi_bready,

            s_axi_araddr              => (others => '0'), -- axi_in.s_axi_araddr,
            s_axi_arvalid             => '0',             -- axi_in.s_axi_arvalid,
            s_axi_arready             => open,            -- axi_out.s_axi_arready,
            s_axi_rdata               => open,            -- axi_out.s_axi_rdata,
            s_axi_rresp               => open,            -- axi_out.s_axi_rresp,
            s_axi_rvalid              => open,            -- axi_out.s_axi_rvalid,
            s_axi_rready              => '0',             -- axi_in.s_axi_rready,
            -- Clock out ports
            clk_out1                  => vga_clk_bufg,
            -- Status and control signals
            power_down                => mmcm_pwrdwn,
            locked                    => locked,
            -- Clock in ports
            clk_in1                   => refclk
        );

    -- Hold power down signal to 0 for now. Can be used to disable output at some point.
    mmcm_pwrdwn <= '0';

    -- Map correct clock and reset into axi bus
    axi_in.s_axi_aclk    <= clk;
    axi_in.s_axi_aresetn <= rstn;

end architecture rtl;
