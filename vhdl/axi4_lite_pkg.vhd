library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package axi4_lite_pkg is

    type axi4_lite_slave_in_t is record
        s_axi_aclk              : std_logic;
        s_axi_aresetn           : std_logic;
        s_axi_awaddr            : std_logic_vector(10 downto 0);
        s_axi_awvalid           : std_logic;
        s_axi_wdata             : std_logic_vector(31 downto 0);
        s_axi_wstrb             : std_logic_vector(3 downto 0);
        s_axi_wvalid            : std_logic;
        s_axi_bready            : std_logic;
        s_axi_araddr            : std_logic_vector(10 downto 0);
        s_axi_arvalid           : std_logic;
        s_axi_rready            : std_logic;
    end record axi4_lite_slave_in_t;

    type axi4_lite_slave_out_t is record
        s_axi_awready   : std_logic;
        s_axi_wready    : std_logic;
        s_axi_bresp     : std_logic_vector(1 downto 0);
        s_axi_bvalid    : std_logic;
        s_axi_arready   : std_logic;
        s_axi_rdata     : std_logic_vector(31 downto 0);
        s_axi_rresp     : std_logic_vector(1 downto 0);
        s_axi_rvalid    : std_logic;
    end record axi4_lite_slave_out_t;

end package axi4_lite_pkg;

package body axi4_lite_pkg is

end package body axi4_lite_pkg;
