library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab5 is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab5;

architecture RTL of lab5 is
  component vga_adapter
    generic(RESOLUTION : string);
    port (resetn                                       : in  std_logic;
          clock                                        : in  std_logic;
          colour                                       : in  std_logic_vector(2 downto 0);
          x                                            : in  std_logic_vector(7 downto 0);
          y                                            : in  std_logic_vector(6 downto 0);
          plot                                         : in  std_logic;
          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
			 
  end component;
  
  signal x      : std_logic_vector(7 downto 0);
  signal y      : std_logic_vector(6 downto 0);
  signal colour : std_logic_vector(2 downto 0);
  signal plot   : std_logic;  
  
begin

	 vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120") 
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => x,
             y         => y,
             plot      => plot,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);
		
process(CLOCK_50,KEY(3))
  variable int_value : std_logic_vector(1 downto 0);
  variable countX : integer range 0 to 159;
  variable countY : integer range 0 to 119;
  variable colourVar : std_logic_vector(2 downto 0);
  variable Xinitial : std_logic_vector (7 downto 0) := "01010000";
  variable Yinitial : std_logic_vector (6 downto 0) := "0111100";  
begin		
	if(KEY(3) = '1') then -- Reset
		int_value := "00";
   elsif(CLOCK_50'event and CLOCK_50 = '1') then -- each time a counter overflows, 1 bit is plotted on screen
	if(KEY(0) = '1') then -- Each time Key(0) is pressed, a line is plotted
		int_value := "01";
	end if;
	
	case int_value is
		when "00" =>
		Xinitial := "00000000";
		Yinitial := "0000000";
		if(countX > 159) then
			countY := countY + 1;
			countX := 0;
		else
			countX := countX + 1;
		end if;
		if(countY > 119) then
			countY := 0;
		end if;
		
		if(countY = 0) then
		colourVar := "111";
		elsif(countY = 119) then
		colourVar := "111";
		elsif(countX = 3) then
		if(countY >= 20 and countY <= 30) then
		colourVar := "001";
		end if;
		elsif(countX = 25) then
		if(countY >= 31 and countY <= 41) then
		colourVar := "001";
		end if;
		elsif(countX = 125) then
		if(countY >= 20 and countY <= 30) then
		colourVar := "100";
		end if;
		elsif(countX = 155) then
		if(countY >= 31 and countY <= 41) then
		colourVar := "100";
		end if;
		else
		colourVar := "000";
		end if;
		plot <= '1';
		x <= std_logic_vector(to_unsigned(countX,8));
		y <= std_logic_vector(to_unsigned(countY,7));
		
		when others =>
		plot <= '0';
		end case;
		
		colour <= colourVar;
		end if;
		end process;
end RTL;


