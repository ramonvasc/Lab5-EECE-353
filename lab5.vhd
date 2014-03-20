library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab5 is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(3 downto 0);
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
  signal slow_clock: std_logic_vector (18 downto 0); 
  signal variable_clock : std_logic;
  signal clock_selector : std_logic_vector (1 downto 0);
  signal XpositionB1  : integer range 0 to 159;
  signal YpositionB1  : integer range 0 to 119;
  signal XpositionB2  : integer range 0 to 159;
  signal YpositionB2  : integer range 0 to 119;
  signal XpositionR1  : integer range 0 to 159;
  signal YpositionR1  : integer range 0 to 119;
  signal XpositionR2  : integer range 0 to 159;
  signal YpositionR2  : integer range 0 to 119; 
  signal Xposition : std_logic_vector (7 downto 0);
  signal Yposition : std_logic_vector (6 downto 0);  
  signal Xlength : signed (8 downto 0);
  signal Ylength : signed (7 downto 0);  
  signal Xsignal : signed (3 downto 0);
  signal Ysignal : signed (3 downto 0);  
 
  procedure plotPixel (xPixel,yPixel : integer) is --VHDL function to plot my pixels
  begin
  			plot <= '1';
			x <= std_logic_vector(to_unsigned(xPixel,8));
			y <= std_logic_vector(to_unsigned(yPixel,7));
  end plotPixel; 
  
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
				 
process(CLOCK_50)
  variable slow_clock_var: unsigned (18 downto 0);
begin
	if (CLOCK_50'event and CLOCK_50 = '1') then
	slow_clock_var:= unsigned (slow_clock);
   slow_clock_var:=  slow_clock_var + 1;
   end if;
	slow_clock <= std_logic_vector (slow_clock_var); 
end process; 				 
		
process(clock_selector)
begin		
	if(clock_selector = "00") then
	variable_clock <= CLOCK_50;
	elsif(clock_selector = "01") then
	variable_clock <= slow_clock(slow_clock'left);
	elsif(clock_selector = "10") then
	variable_clock <= slow_clock(slow_clock'left - 1);
	else
	variable_clock <= slow_clock(slow_clock'left - 2);
	end if;
end process;

process(variable_clock,KEY(3))
  variable int_value : std_logic_vector(4 downto 0);
  variable gameSpeed : integer range 0 to 600 := 0;
  variable countX : integer range 0 to 159;
  variable countY : integer range 0 to 119;
  variable colourVar : std_logic_vector(2 downto 0);
  variable countYB1 : integer range 0 to 119 := 30;
  variable countOldYB1 : integer range 0 to 119 := 30;
  variable countYB2 : integer range 0 to 119 := 41;
  variable countOldYB2 : integer range 0 to 119 := 41;
  variable countYR1 : integer range 0 to 119 := 30;
  variable countOldYR1 : integer range 0 to 119 := 30;
  variable countYR2 : integer range 0 to 119 := 41; 
  variable countOldYR2 : integer range 0 to 119 := 41;
  variable XinitialVar: unsigned (7 downto 0):= "01010000";
  variable YinitialVar: unsigned (6 downto 0):= "0111100";
  variable Xinitial : std_logic_vector (7 downto 0);
  variable Yinitial : std_logic_vector (6 downto 0);   
  variable countOldPuckXinitial : integer range 0 to 159;
  variable countOldPuckYinitial : integer range 0 to 119;
  variable Initial_error : signed (8 downto 0);
  variable Actual_error : signed (17 downto 0);
  
begin		
	if(KEY(3) = '0') then -- Reset
		int_value := "00000";
   elsif(variable_clock'event and variable_clock = '1') then --uses the clock selected ,can be a fast or slow clock
	if(KEY(0) = '0') then
		int_value := "11111";
	end if;
	case int_value is
		when "00000" => --restart the game
		clock_selector <= "00";
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
		XpositionB1 <= countX;
		if(countY >= 20 and countY <= 30) then
		colourVar := "001";
		YpositionB1 <= countY;
		end if;
		elsif(countX = 25) then
		XpositionB2 <= countX;
		if(countY >= 31 and countY <= 41) then
		colourVar := "001";
		YpositionB2 <= countY;
		end if;
		elsif(countX = 125) then
		XpositionR1 <= countX;
		if(countY >= 20 and countY <= 30) then
		colourVar := "100";
		YpositionR1 <= countY;
		end if;
		elsif(countX = 155) then
		XpositionR2 <= countX;
		if(countY >= 31 and countY <= 41) then
		colourVar := "100";
		YpositionR2 <= countY;
		end if;
		else
		colourVar := "000";
		end if;
		XinitialVar := "01010000";
		YinitialVar := "0111100";
		--countOldPuckXinitial := 80;
		--countOldPuckYinitial := 60;
		--Xsignal <= to_signed(0,4);
		--Ysignal <= to_signed(0,4);
		--initial_error := to_signed(0,9);
		--Actual_error := to_signed(0,18);
		countYB1 := 30; 
		countYB2 := 41;
		countYR1 := 30;
		countYR2 := 41;
		plotPixel(countX,countY);
		
		when "00001" => --plot player blue 1
		if(SW(0) = '1') then
			if((countYB1 + 10) <= 118) then
			countOldYB1 := countYB1 + 10;
			else
			countYB1 := countYB1 - 1;
			countOldYB1 := 1;
			end if;
			if(countYB1 > 1) then
			countYB1 := countYB1 - 1;
			end if;		
		elsif(SW(0) = '0') then	
			if((countYB1 - 10) >=1) then
			countOldYB1 := countYB1 - 10;
			else
			countYB1 := countYB1 + 1;
			countOldYB1 := 118;
			end if;
			if(countYB1 < 118) then
			countYB1 := countYB1 + 1;
			end if;
		end if;
			colourVar := "001";
			plotPixel(XpositionB1,countYB1);
			int_value := "00010";
			
		when "00010" => --erase player blue 1
		colourVar := "000";
		plotPixel(XpositionB1,countOldYB1);
		int_value := "00011";
		
		when "00011" => --plot player blue 2
		if(SW(1) = '1') then
			if((countYB2 + 10) <= 118) then
			countOldYB2 := countYB2 + 10;
			else
			countYB2 := countYB2 - 1;
			countOldYB2 := 1;
			end if;
			if(countYB2 > 1) then
			countYB2 := countYB2 - 1;
			end if;		
		elsif(SW(1) = '0') then	
			if((countYB2 - 10) >=1) then
			countOldYB2 := countYB2 - 10;
			else
			countYB2 := countYB2 + 1;
			countOldYB2 := 118;
			end if;		
			if(countYB2 < 118) then
			countYB2 := countYB2 + 1;
			end if;
		end if;
			colourVar := "001";
			plotPixel(XpositionB2,countYB2);
			int_value := "00100";
			
		when "00100" => --erase player blue 2
		colourVar := "000";
		plotPixel(XpositionB2,countOldYB2);
		int_value := "00101";
		
		when "00101" => --plot player red 1
		if(SW(2) = '1') then
			if((countYR1 + 10) <= 118) then
			countOldYR1 := countYR1 + 10;
			else
			countYR1 := countYR1 - 1;
			countOldYR1 := 1;
			end if;
			if(countYR1 > 1) then
			countYR1 := countYR1 - 1;
			end if;		
		elsif(SW(2) = '0') then	
			if((countYR1 - 10) >=1) then
			countOldYR1 := countYR1 - 10;
			else
			countYR1 := countYR1 + 1;
			countOldYR1 := 118;
			end if;		
			if(countYR1 < 118) then
			countYR1 := countYR1 + 1;
			end if;
		end if;
			colourVar := "100";
			plotPixel(XpositionR1,countYR1);
			int_value := "00110";
			
		when "00110" => --erase player red 1
		colourVar := "000";
		plotPixel(XpositionR1,countOldYR1);
		int_value := "00111";
		
		when "00111" => --plot player red 2
		if(SW(3) = '1') then
			if((countYR2 + 10) <= 118) then
			countOldYR2 := countYR2 + 10;
			else
			countYR2 := countYR2 - 1;
			countOldYR2 := 1;
			end if;
			if(countYR2 > 1) then
			countYR2 := countYR2 - 1;
			end if;		
		elsif(SW(3) = '0') then	
			if((countYR2 - 10) >=1) then
			countOldYR2 := countYR2 - 10;
			else
			countYR2 := countYR2 + 1;
			countOldYR2 := 118;
			end if;
			if(countYR2 < 118) then
			countYR2 := countYR2 + 1;
			end if;
		end if;
			colourVar := "100";
			plotPixel(XpositionR2,countYR2);
			int_value := "01000";
			
		when "01000" => --erase player red 2
		colourVar := "000";
		plotPixel(XpositionR2,countOldYR2);
		int_value := "01001";
		
		when "01001" => --puck movement plot
		if ((YinitialVar > 1) AND (Ysignal = -1)) then
		countOldPuckXinitial := to_integer(XinitialVar);
		countOldPuckYinitial := to_integer(YinitialVar);
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar -1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(-1,4);
		end if;
		
		if ((YinitialVar < 1) AND (Ysignal = -1)) then
		countOldPuckXinitial := to_integer(XinitialVar);
		countOldPuckYinitial := to_integer(YinitialVar);
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar +1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(1,4);
		end if;
		
		If ((XinitialVar > 1) AND (Xsignal = 1)) then
		countOldPuckXinitial := to_integer(XinitialVar);
		countOldPuckYinitial := to_integer(YinitialVar);		
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar -1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(-1,4);
		end if;
		
		If ((XinitialVar < 1) AND (Xsignal = 1)) then
		countOldPuckXinitial := to_integer(XinitialVar);
		countOldPuckYinitial := to_integer(YinitialVar);		
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar -1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(-1,4);
		end if;
		
		Xinitial := std_logic_vector (XinitialVar);
		Yinitial := std_logic_vector (YinitialVar);
				
		Xlength <= "000001111";
		Ylength <= "00001111";
		
		if ((Xposition /= Xinitial) and (Yposition /= Yinitial)) then
		Actual_error := 2*Initial_error;
		else
		int_value := "11110";
		end if;
		
		if(Actual_error > 0-Ylength) then
		Initial_error := Initial_error - Ylength;
		Xposition <= std_logic_vector(signed(Xinitial) + Xsignal); -- was Xinitial
		end if;

		if(Actual_error < Xlength) then
		Initial_error := Initial_error + Xlength;
		Yposition <= std_logic_vector(signed(Yinitial) + Ysignal); -- was Yinitial
		end if;
		colourVar := "111";
		plot <= '1';
		x <= Xinitial;
		y <= Yinitial;
		int_value := "01010";
		
		when "01010" => --puck movement erase
		colourVar := "000";
		plotPixel(countOldPuckXinitial, countOldPuckYinitial);
		int_value := "11110";
		
		when "11110" => --game speed based on a counter
		gameSpeed := gameSpeed + 1;
		if(gameSpeed = 200) then
		clock_selector <= "10";
		end if;
		if(gameSpeed = 400) then
		clock_selector <= "11";
		end if;
		if(gameSpeed = 1) then 
		clock_selector <= "01";
		end if;
		int_value := "00001";
		
		when others =>
		plot <= '0';
		clock_selector <= "01";
		int_value := "00001";
		
		end case;
		colour <= colourVar;
		end if;
end process;
		
end RTL;


