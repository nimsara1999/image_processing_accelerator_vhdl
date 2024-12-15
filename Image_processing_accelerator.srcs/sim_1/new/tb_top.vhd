library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_top is
    -- No ports for a testbench
end tb_top;

architecture Behavioral of tb_top is
    -- Component Declaration
    component top is
        Port (
        clk10     : in  STD_LOGIC; -- 100 MHz clock input
        vga_red    : out STD_LOGIC_VECTOR(3 downto 0); -- 4-bit VGA red
        vga_green  : out STD_LOGIC_VECTOR(3 downto 0); -- 4-bit VGA green
        vga_blue   : out STD_LOGIC_VECTOR(3 downto 0); -- 4-bit VGA blue
        vga_hsync  : out STD_LOGIC; -- Horizontal sync signal
        vga_vsync  : out STD_LOGIC;  -- Vertical sync signal
        LED : out STD_LOGIC_VECTOR(1 downto 0);
        SW : in STD_LOGIC_VECTOR(1 DOWNTO 0)

        );
    end component;

    -- Signals for connecting to the top module
    signal clk10     : STD_LOGIC := '0'; -- Clock signal
    signal vga_red    : STD_LOGIC_VECTOR(3 downto 0);
    signal vga_green  : STD_LOGIC_VECTOR(3 downto 0);
    signal vga_blue   : STD_LOGIC_VECTOR(3 downto 0);
    signal vga_hsync  : STD_LOGIC;
    signal vga_vsync  : STD_LOGIC;
    signal leds   : STD_LOGIC_VECTOR(1 downto 0);
    signal sw : STD_LOGIC_VECTOR(1 downto 0);


begin

    -- Instantiate the Top Module
    uut: top
    port map (
        clk10     => clk10,
        vga_red    => vga_red,
        vga_green  => vga_green,
        vga_blue   => vga_blue,
        vga_hsync  => vga_hsync,
        vga_vsync  => vga_vsync,
        LED => leds,
        sw => sw
    );

    -- Clock Generation: 100 MHz
    clk_process : process
    begin
        clk10 <= '0';
        wait for 5 ns;
        clk10 <= '1';
        wait for 5 ns;
    end process;

end Behavioral;
