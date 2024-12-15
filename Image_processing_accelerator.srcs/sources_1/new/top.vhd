library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity top is
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
end top;

architecture Behavioral of top is
    -- Grayscale pixel data (4 bits instead of 8 bits)
    signal frame_pixel : STD_LOGIC_VECTOR(3 downto 0);  -- 4-bit grayscale data
    signal frame_addr  : STD_LOGIC_VECTOR(19 downto 0); -- Address for 320x240 image
    signal data_from_ramb_to_vga_sig    : STD_LOGIC_VECTOR(3 downto 0);  -- Data from RAM (4-bit grayscale)
    signal kernel_pixel : STD_LOGIC_VECTOR(3 downto 0); -- Pixel output from the kernel module
    signal output_from_fetcher_valid_bit_sig : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal calculated_data_from_fetcher_to_ram : STD_LOGIC_VECTOR(3 downto 0);
    signal addr_from_fetcher_to_ram_sig : STD_LOGIC_VECTOR(19 downto 0);
    signal single_pixel_data_from_ram_to_fetcher_sig : STD_LOGIC_VECTOR(3 downto 0);
    signal main_pixel_address : STD_LOGIC_VECTOR(19 downto 0) := (others => '0');
    signal pixel_matrix_36_bit : STD_LOGIC_VECTOR(35 downto 0);
    signal write_enable_from_fetcher_to_rama : STD_LOGIC_VECTOR(0 DOWNTO 0) := (others => '0');
    signal sw_sig : STD_LOGIC_VECTOR(1 DOWNTO 0);


begin

    -- Instantiate the VGA Controller
    vga_inst : entity work.vga_controller
    port map (
        clk10     => clk10,
        vga_red    => vga_red,  -- Connect grayscale to R, G, and B
        vga_green  => vga_green, -- Connect grayscale to R, G, and B
        vga_blue   => vga_blue,  -- Connect grayscale to R, G, and B
        vga_hsync  => vga_hsync,
        vga_vsync  => vga_vsync,
        frame_addr => frame_addr, -- Address signal for frame buffer
        frame_pixel => data_from_ramb_to_vga_sig -- Read pixel data from image kernel module
    );
    
--    frame_addr <= std_logic_vector(to_unsigned(350006, 20));
    LED <= SW;
    sw_sig <= SW;
    
    blk_mem_gen_inst : entity work.blk_mem_gen_0
    port map (
       clka => clk10,
       wea => write_enable_from_fetcher_to_rama,
       addra => addr_from_fetcher_to_ram_sig,
       dina => calculated_data_from_fetcher_to_ram,
       douta => single_pixel_data_from_ram_to_fetcher_sig,
       clkb => clk10,
       web => "0",
       addrb => frame_addr,
       dinb => "0000",
       doutb => data_from_ramb_to_vga_sig
   );
       
   fetcher_inst : entity work.Pixel_Window_Fetcher
   port map(
       clk                   => clk10,
       addr_in               => main_pixel_address, -- will be incremented by the process in a slow clk
       pixel_data_in         => single_pixel_data_from_ram_to_fetcher_sig,   -- 4-bit pixel data from RAM douta
       addr_out              => addr_from_fetcher_to_ram_sig, -- 20-bit address to be sent to RAM addra
       pixel_data_out        => pixel_matrix_36_bit, -- 9 pixels x 4 bits each = 36-bit output
       calculated_data_to_ram => calculated_data_from_fetcher_to_ram,
       pixel_data_out_valid  => output_from_fetcher_valid_bit_sig, -- Signal to indicate when output is valid
       write_enable_in_rama  => write_enable_from_fetcher_to_rama,
       sw_input              => sw_sig
   );
    
    process(clk10)
    begin
        if rising_edge(clk10) then
            if output_from_fetcher_valid_bit_sig = "1" then
                main_pixel_address <= std_logic_vector(unsigned(main_pixel_address) + to_unsigned(1, 20));
            end if;
            
            if unsigned(main_pixel_address) >= 307300 then
                main_pixel_address <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
