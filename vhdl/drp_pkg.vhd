library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

package drp_pkg is

    type drp_in_t is record
        daddr       : std_logic_vector(6 downto 0);
        dclk        : std_logic;
        den         : std_logic;
        din         : std_logic_vector(15 downto 0);
        dwe         : std_logic;
    end record drp_in_t;

    type drp_out_t is record
        dout  : std_logic_vector(15 downto 0);
        drdy  : std_logic;
    end record drp_out_t;

end package drp_pkg;
