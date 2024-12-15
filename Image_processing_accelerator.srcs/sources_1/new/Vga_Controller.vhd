library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    Port (
        clk10      : in  STD_LOGIC; -- 100 MHz clock input from BASYS 3
        vga_red     : out STD_LOGIC_VECTOR(3 downto 0); -- 4-bit VGA red
        vga_green   : out STD_LOGIC_VECTOR(3 downto 0); -- 4-bit VGA green
        vga_blue    : out STD_LOGIC_VECTOR(3 downto 0); -- 4-bit VGA blue
        vga_hsync   : out STD_LOGIC; -- Horizontal sync signal
        vga_vsync   : out STD_LOGIC; -- Vertical sync signal
        frame_addr  : out STD_LOGIC_VECTOR(19 downto 0); -- Address to frame buffer
        frame_pixel : in  STD_LOGIC_VECTOR(3 downto 0)   -- 8-bit grayscale pixel data from frame buffer
    );
end vga_controller;

architecture Behavioral of vga_controller is
    -- Clock divider signals
    signal slow_clk : STD_LOGIC := '0';
    signal counter : unsigned(1 downto 0) := (others => '0'); -- 2-bit counter

    -- VGA timing constants
    constant hRez       : natural := 640;  -- Horizontal resolution
    constant hStartSync : natural := 640 + 16; -- Start of hsync pulse
    constant hEndSync   : natural := 640 + 16 + 96; -- End of hsync pulse
    constant hMaxCount  : natural := 800; -- Total horizontal line time

    constant vRez       : natural := 480;  -- Vertical resolution
    constant vStartSync : natural := 480 + 10; -- Start of vsync pulse
    constant vEndSync   : natural := 480 + 10 + 2; -- End of vsync pulse
    constant vMaxCount  : natural := 525; -- Total vertical frame time

    constant hsync_active : std_logic := '0'; -- Active-low hsync
    constant vsync_active : std_logic := '0'; -- Active-low vsync

    -- Signals for horizontal and vertical counters
    signal hCounter : unsigned(9 downto 0) := (others => '0');
    signal vCounter : unsigned(9 downto 0) := (others => '0');
    signal address  : unsigned(19 downto 0) := (others => '0'); -- Frame buffer address
    signal blank    : std_logic := '1'; -- Blanking signal
    
begin
    -- Frame address assignment
    frame_addr <= std_logic_vector(unsigned(address) + to_unsigned(350000, 20));

    -- Clock Divider Process: 100 MHz -> 25 MHz
    process(clk10)
    begin
        if rising_edge(clk10) then
            counter <= counter + 1;
        end if;
    end process;

    slow_clk <= counter(1); -- Output of clock divider (MSB) as 25 MHz clock

 
    -- VGA Timing Process
    process(slow_clk)
    begin
        if rising_edge(slow_clk) then
            -- Count horizontal pixels and vertical lines
            if hCounter = hMaxCount - 1 then
                hCounter <= (others => '0');
                if vCounter = vMaxCount - 1 then
                    vCounter <= (others => '0');
                    address <= (others => '0'); -- Reset address at the end of the frame
                else
                    vCounter <= vCounter + 1;
                end if;
            else
                hCounter <= hCounter + 1;
            end if;
    
            -- Generate VGA signals for grayscale
            if blank = '0' then
                vga_red   <= frame_pixel; -- Use 4 MSB of grayscale pixel
                vga_green <= frame_pixel; -- Use 4 MSB of grayscale pixel
                vga_blue  <= frame_pixel; -- Use 4 MSB of grayscale pixel                
            else
                vga_red   <= (others => '0');
                vga_green <= (others => '0');
                vga_blue  <= (others => '0');
            end if;
    
            -- Blanking logic
            if vCounter >= vRez then
                blank <= '1';
            else
                if hCounter < hRez then
                    blank <= '0';
                    address <= address + 1; -- Increment address for each pixel
                else
                    blank <= '1';
                end if;
            end if;
    
            -- Horizontal sync logic
            if hCounter > hStartSync and hCounter <= hEndSync then
                vga_hsync <= hsync_active;
            else
                vga_hsync <= not hsync_active;
            end if;
    
            -- Vertical sync logic
            if vCounter >= vStartSync and vCounter < vEndSync then
                vga_vsync <= vsync_active;
            else
                vga_vsync <= not vsync_active;
            end if;
        end if;
    end process;

 
 
end Behavioral;
