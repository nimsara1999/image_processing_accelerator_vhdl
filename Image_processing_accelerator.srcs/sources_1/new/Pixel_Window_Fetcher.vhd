library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pixel_Window_Fetcher is
    Port (
        clk                   : in  STD_LOGIC;
        addr_in               : in  STD_LOGIC_VECTOR(19 downto 0); -- 20-bit address of the input pixel
        pixel_data_in         : in  STD_LOGIC_VECTOR(3 downto 0);   -- 4-bit pixel data from RAM douta
        addr_out              : out STD_LOGIC_VECTOR(19 downto 0); -- 20-bit address to be sent to RAM addra
        pixel_data_out        : out STD_LOGIC_VECTOR(35 downto 0); -- 9 pixels x 4 bits each = 36-bit output
        calculated_data_to_ram : out STD_LOGIC_VECTOR(3 downto 0);
        pixel_data_out_valid  : out STD_LOGIC_VECTOR(0 DOWNTO 0);                      -- Signal to indicate when output is valid
        write_enable_in_rama  : out STD_LOGIC_VECTOR(0 DOWNTO 0);                      -- Signal to indicate when output is valid
        sw_input              : in STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
end Pixel_Window_Fetcher;

architecture Behavioral of Pixel_Window_Fetcher is

    type integer_vector is array (natural range <>) of integer;

    -- Image dimensions
    constant IMG_WIDTH  : integer := 640;  -- Update as needed (currently set to 5x5 image)
    constant IMG_HEIGHT : integer := 480;  -- Update as needed

    -- Counter to manage the 9 clock cycles needed to fetch 9 pixels
    signal counter : integer range 0 to 28 := 0;

    -- Signal to track the 3x3 window pixel addresses
    type pixel_address_array_type is array (0 to 8) of STD_LOGIC_VECTOR(19 downto 0);
    signal pixel_addresses : pixel_address_array_type;

    -- 9 4-bit pixel data registers to store the 3x3 pixel window
    signal pixel_buffer : STD_LOGIC_VECTOR(35 downto 0) := (others => '0'); -- 9 pixels, each 4 bits, total 36 bits

    -- State signal to indicate if the module is ready (runs after ram a write is done)
    signal valid_output : STD_LOGIC_VECTOR(0 DOWNTO 0) := (others => '0');

    -- Register for addr_in to detect changes
    signal last_addr_in : STD_LOGIC_VECTOR(19 downto 0) := "11111111111111111111";
    
    -- Register for addr_in to detect changes
    signal addr_out_sig : STD_LOGIC_VECTOR(19 downto 0) := (others => '0');
    
    signal pixel_data_out_to_ram : STD_LOGIC_VECTOR(3 downto 0);   -- 4-bit pixel data to RAM douta

    -- signal to enable write in ram port a (runs from counter = 14 to counter = 25)
    signal write_enable_in_rama_sig : STD_LOGIC_VECTOR(0 DOWNTO 0) := (others => '0');
    
    signal sw_input_sig : STD_LOGIC_VECTOR(1 DOWNTO 0) := (others => '0');

    -- Helper signals
    signal current_row : integer;
    signal current_col : integer;

    -- Helper function to clamp pixel addresses within valid boundaries
    function clamp_pixel_address(row, col : integer) return STD_LOGIC_VECTOR is
        variable clamped_row : integer;
        variable clamped_col : integer;
    begin
        -- Clamp row to valid range
        if row < 0 then
            clamped_row := 0;
        elsif row >= IMG_HEIGHT then
            clamped_row := IMG_HEIGHT - 1;
        else
            clamped_row := row;
        end if;

        -- Clamp column to valid range
        if col < 0 then
            clamped_col := 0;
        elsif col >= IMG_WIDTH then
            clamped_col := IMG_WIDTH - 1;
        else
            clamped_col := col;
        end if;

        -- Return the clamped address
        return std_logic_vector(to_unsigned(clamped_row * IMG_WIDTH + clamped_col, 20));
    end function;
    
    
    -- Function declaration
    function multiply_matrix_with_kernel( 
        pixel_buffer : STD_LOGIC_VECTOR(35 downto 0); 
        sw_inputs : STD_LOGIC_VECTOR(1 DOWNTO 0)
    ) return STD_LOGIC_VECTOR is
         type kernel_array is array(0 to 8) of integer;
         constant kernel1 : kernel_array := (0, -1, 0, -1, 7, -1, 0, -1, 0); -- sharpness
         constant kernel2 : kernel_array := (1, 1, 1, 1, 1, 1, 1, 1, 1); -- blur
         constant kernel3 : kernel_array := (-1, -1, -1, -1, 8, -1, -1, -1, -1); -- edge
         variable sum_kernel1 : integer := 3;
         variable sum_kernel2 : integer := 9;
         variable sum_kernel3 : integer := 4;
         variable kernel : kernel_array := (0, 0, 0, 0, 1, 0, 0, 0, 0); -- edge
         variable sum_kernel : integer := 1;
         variable total : integer := 0;
         variable total_temp : integer := 0;
         variable pixel_values : integer_vector(0 to 8);
         variable result_pixel_value_after_kernel_1 : integer;
         variable result_pixel_value : integer;
         variable i : integer;
     begin
         -- Extract pixel values from the pixel buffer
         pixel_values(0) := to_integer(unsigned(pixel_buffer(35 downto 32))); -- Top-left
         pixel_values(1) := to_integer(unsigned(pixel_buffer(31 downto 28))); -- Top-middle
         pixel_values(2) := to_integer(unsigned(pixel_buffer(27 downto 24))); -- Top-right
         pixel_values(3) := to_integer(unsigned(pixel_buffer(23 downto 20))); -- Mid-left
         pixel_values(4) := to_integer(unsigned(pixel_buffer(19 downto 16))); -- Center
         pixel_values(5) := to_integer(unsigned(pixel_buffer(15 downto 12))); -- Mid-right
         pixel_values(6) := to_integer(unsigned(pixel_buffer(11 downto 8)));  -- Bottom-left
         pixel_values(7) := to_integer(unsigned(pixel_buffer(7 downto 4)));   -- Bottom-middle
         pixel_values(8) := to_integer(unsigned(pixel_buffer(3 downto 0)));   -- Bottom-right
     
        if (sw_inputs = "00") then
            result_pixel_value := pixel_values(4);
        else
         case sw_inputs is
            when "01" => kernel := kernel1;
            when "10" => kernel := kernel2;
            when "11" => kernel := kernel3;
            when others => null;
         end case;
         
         case sw_inputs is
            when "01" => sum_kernel := sum_kernel1;
            when "10" => sum_kernel := sum_kernel2;
            when "11" => sum_kernel := sum_kernel3;
            when others => null;
         end case;
         
         -- apply final kernel
          for i in 0 to 8 loop
              total := total + (kernel(i) * pixel_values(i));
          end loop;
      
          -- Avoid division by zero
          if sum_kernel = 0 then
              result_pixel_value := 0;
          else
              result_pixel_value := total / sum_kernel;
          end if;
        end if;           
         -- Return the result as a 4-bit value
         return std_logic_vector(to_unsigned(result_pixel_value, 4));
     end function;

begin

process(clk)
    variable current_row_var : integer; -- Declare variables for immediate updates
    variable current_col_var : integer;
    variable temp_pixel_addresses : pixel_address_array_type; -- Temporary variable for immediate updates
    
    begin
        if rising_edge(clk) then
            if addr_in /= last_addr_in then
                -- New input address detected
                last_addr_in <= addr_in; -- Update the stored address
                counter <= 1;            -- Reset the counter
                valid_output <= "0";     -- Reset valid output signal
                sw_input_sig <= sw_input;

                -- Decode current row and column
                current_row_var := to_integer(unsigned(addr_in)) / IMG_WIDTH;
                current_col_var := to_integer(unsigned(addr_in)) mod IMG_WIDTH;
    
                -- Calculate addresses for 3x3 window with boundary checks using a variable
                temp_pixel_addresses(0) := clamp_pixel_address(current_row_var - 1, current_col_var - 1); -- Top-left
                temp_pixel_addresses(1) := clamp_pixel_address(current_row_var - 1, current_col_var);     -- Top-middle
                temp_pixel_addresses(2) := clamp_pixel_address(current_row_var - 1, current_col_var + 1); -- Top-right
                temp_pixel_addresses(3) := clamp_pixel_address(current_row_var, current_col_var - 1);     -- Mid-left
                temp_pixel_addresses(4) := clamp_pixel_address(current_row_var, current_col_var);         -- Center
                temp_pixel_addresses(5) := clamp_pixel_address(current_row_var, current_col_var + 1);     -- Mid-right
                temp_pixel_addresses(6) := clamp_pixel_address(current_row_var + 1, current_col_var - 1); -- Bottom-left
                temp_pixel_addresses(7) := clamp_pixel_address(current_row_var + 1, current_col_var);     -- Bottom-middle
                temp_pixel_addresses(8) := clamp_pixel_address(current_row_var + 1, current_col_var + 1); -- Bottom-right
    
                -- Assign variable values to signal
                pixel_addresses <= temp_pixel_addresses;
    
            elsif counter = 1 then
                -- Wait for pixel_addresses to be updated
                counter <= 2;
    
            elsif counter > 1 and counter <= 10 then
                -- Output the address corresponding to the current counter
                addr_out_sig <= pixel_addresses(counter - 2); -- Adjust index to account for delay
                -- Store the pixel data from RAM into the appropriate position in pixel_buffer
                case counter is
                    when 5 => pixel_buffer(35 downto 32) <= pixel_data_in; -- Top-left
                    when 6 => pixel_buffer(31 downto 28) <= pixel_data_in; -- Top-middle
                    when 7 => pixel_buffer(27 downto 24) <= pixel_data_in; -- Top-right
                    when 8 => pixel_buffer(23 downto 20) <= pixel_data_in; -- Mid-left
                    when 9 => pixel_buffer(19 downto 16) <= pixel_data_in; -- Center
                    when 10 => pixel_buffer(15 downto 12) <= pixel_data_in; -- Mid-right
                    when others => null;
                end case;
                counter <= counter + 1;
                
            elsif counter = 11 then
                counter <= counter + 1;
                pixel_buffer(11 downto 8)  <= pixel_data_in;
                                
            elsif counter = 12 then
                counter <= counter + 1;
                pixel_buffer(7 downto 4)   <= pixel_data_in;
                            
            elsif counter = 13 then
                counter <= counter + 1;
                pixel_buffer(3 downto 0)   <= pixel_data_in;
                            
            elsif counter >= 14 and counter < 20 then
                -- Output the 36-bit 3x3 pixel data
                counter <= counter + 1;
                write_enable_in_rama_sig <= "1";
                addr_out_sig <= std_logic_vector(unsigned(addr_in) + to_unsigned(350000, 20));
                calculated_data_to_ram <= multiply_matrix_with_kernel(pixel_buffer, sw_input_sig);
--                calculated_data_to_ram <= pixel_buffer(19 downto 16);
            
            elsif counter = 20 then
                write_enable_in_rama_sig <= "0";
                counter <= counter + 1;

            elsif counter = 21 then
                valid_output <= "1";
                counter <= counter + 1;

            elsif counter = 22 then
                valid_output <= "0";
                counter <= 0; -- Reset the counter
            
            end if;
        end if;
    end process;

    pixel_data_out_valid <= valid_output;
    write_enable_in_rama <= write_enable_in_rama_sig;
    addr_out <= addr_out_sig;
    pixel_data_out <= pixel_buffer;


end Behavioral;
