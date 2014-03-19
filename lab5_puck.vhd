-- Antonio Ramon Vasconcelos de Freitas 66546128
-- Clovis Fritzen 64333131

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity lab5_puck is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab5_puck;

architecture rtl of lab5_puck is

 --Component from the Verilog file: vga_adapter.v

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
  signal int_value : std_logic; 
  signal Xposition : std_logic_vector (7 downto 0);
  signal Yposition : std_logic_vector (6 downto 0); 
  signal Xinitial : std_logic_vector (7 downto 0);
  signal Yinitial : std_logic_vector (6 downto 0); 
  signal Xlength : signed (8 downto 0);
  signal Ylength : signed (7 downto 0);
  signal Xsignal : signed (3 downto 0);
  signal Ysignal : signed (3 downto 0);
  signal Init_error : signed (8 downto 0); 
  signal slow_clock: std_logic_vector (23 downto 0);
  signal clear_dot: std_logic; 
  
begin

  -- includes the vga adapter, which should be in your project 

  
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
        variable slow_clock_var: unsigned (23 downto 0);
		  begin
          if (CLOCK_50'event and CLOCK_50 = '1') then
			 slow_clock_var:= unsigned (slow_clock);
            slow_clock_var:=  slow_clock_var + 1;
          end if;
			slow_clock <= std_logic_vector (slow_clock_var); 
 end process; 
              				 
-- begin of process for X and Y counters
 
 
-- end of process for X and Y counters

 
  process(slow_clock,KEY) -- State machine
  variable countX : integer range 0 to 159;
  variable countY : integer range 0 to 119;
  variable colourVar : std_logic_vector(2 downto 0) := "000"; 
  variable int_value : std_logic_vector(1 downto 0);
  variable Initial_error : signed (8 downto 0) := init_error;
  variable Actual_error : signed (17 downto 0);
  variable XinitialVar: unsigned (7 downto 0):= "01010000";
  variable YinitialVar: unsigned (6 downto 0):= "0111100";
    
  begin
	if(KEY(3) = '0') then -- Reset
		int_value := "00";
   elsif(slow_clock(slow_clock'left)'event and slow_clock(slow_clock'left) = '1') then -- each time a counter overflows, 1 bit is plotted on screen
	if(KEY(0) = '0') then -- Each time Key(0) is pressed, a line is plotted
		int_value := "01";
	end if;
	case int_value is
	 when "00" =>
		
		if(countX > 159) then
			countY := countY + 1;
			countX := 0;
		else
			countX := countX + 1;
		end if;
		if(countY > 119) then
			countY := 0;
		end if;
		colourVar := "000";
		plot <= '1';
		x <= std_logic_vector(to_unsigned(countX,8));
		y <= std_logic_vector(to_unsigned(countY,7));	
	 when "01" => 
				
		If ((YinitialVar > 1) AND (Ysignal = -1)) then
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar -1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(-1,4);
		end if;
		
		If ((YinitialVar < 1) AND (Ysignal = -1)) then
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar +1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(1,4);
		end if;
		
		If ((XinitialVar > 1) AND (Xsignal = 1)) then
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar -1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(-1,4);
		end if;
		
		If ((XinitialVar < 1) AND (Xsignal = 1)) then
		XinitialVar:= XinitialVar +1;
		YinitialVar:= YinitialVar -1;
		Ysignal <= to_signed(1,4);
		else
		Ysignal <= to_signed(-1,4);
		end if;
		
		
		Xinitial <= std_logic_vector (XinitialVar);
		Yinitial <= std_logic_vector (YinitialVar);
				
		Xlength <= "000001111";
		Ylength <= "00001111";
		
		if ((Xposition /= Xinitial) and (Yposition /= Yinitial)) then
		Actual_error := 2*Initial_error;
		else
		int_value := "11";
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
				
	  when others =>
		plot<= '0';
	  end case;
		colour <= colourVar;
	 end if;
	 end process;

end RTL;