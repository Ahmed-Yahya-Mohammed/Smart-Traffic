--  Embedded System Smart Traffic 2 Ways controller Project

--  system recieves input from sensor which corresponds to counting number of cars,
--  then determing the state of each way and the waiting time


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;  
------------------------------------------------------------------------
entity smart_traffic is
 port ( sensor  : in STD_LOGIC; 
        clock  : in STD_LOGIC;  
        reset: in STD_LOGIC; 
        led_out:out std_logic_vector(7 downto 0);
        highway_traffic  : out STD_LOGIC_VECTOR(2 downto 0); 
        road_b_traffic:    out STD_LOGIC_VECTOR(2 downto 0));
end smart_traffic;
------------------------------------------------------------------------
architecture smart_traffic_arc of smart_traffic is
  signal time_1s: std_logic_vector(27 downto 0):= x"0000000";
 signal sec_num:std_logic_vector(3 downto 0):= x"0";
  signal time_10s, time_3s_road_b,time_3s_highway, red_light_enable, yellow_light1_enable,yellow_light2_enable: std_logic:='0';
  signal clock_finish: std_logic; 
  type FSM_States is (highway_green_road_b_red, highway_yellow_road_b_red, highway_red_road_b_green, highway_red_road_b_yellow);
  signal current_state, next_state: FSM_States;
  signal sec_num_reset: std_logic;
  begin

-- Asynchronous reseting (active high) to initial state = open highway and close road_b
   process(clock,reset) 
    begin
     if(reset='0') then
       current_state <= highway_green_road_b_red;
		 sec_num_reset<='1';
     elsif(rising_edge(clock)) then 
       current_state <= next_state; 
		 sec_num_reset<='0';
     end if; 
end process;

   ------------------------------------------------------------
   process(current_state,sensor,time_3s_road_b,time_3s_highway,time_10s,sec_num)
    begin
     case current_state is 
      when highway_green_road_b_red => 
           red_light_enable <= '0';
           yellow_light1_enable <= '0';
           yellow_light2_enable <= '0';
           highway_traffic <= "001";  --traffic is green state(001) 
           road_b_traffic <= "100";   --traffic is red state (100)

      if(sensor = '0') then --detecting cars on road b so getting highway on yellow state
       next_state <= highway_yellow_road_b_red;  
      else 
       next_state <= highway_green_road_b_red; 
      end if;

    when highway_yellow_road_b_red => 
         highway_traffic <= "010";  --yellow state (010)
         road_b_traffic <= "100"; 
         red_light_enable <= '0';
         yellow_light1_enable <= '1';
         yellow_light2_enable <= '0';

    if(time_3s_highway='1') then  -- checking if delay of 3 seconds has occured before turning the traffic on the high way red
     next_state <= highway_red_road_b_green; 
    else 
     next_state <= highway_yellow_road_b_red;  --remain in the same state untill counting finishes
    end if;

    when highway_red_road_b_green => 
         highway_traffic <= "100"; 
         road_b_traffic <= "001"; 
         red_light_enable <= '1';
         yellow_light1_enable <= '0';
         yellow_light2_enable <= '0';

    if(time_10s='1') then  --checking if delay of 10 seconds has occured before turning the traffic on the road_b yellow
     next_state <= highway_red_road_b_yellow;
    else 
     next_state <= highway_red_road_b_green;   --remain in the same state untill counting finishes
    end if;

    when highway_red_road_b_yellow =>
         highway_traffic <= "100"; 
         road_b_traffic <= "010";
         red_light_enable <= '0'; 
         yellow_light1_enable <= '0';
         yellow_light2_enable <= '1';

    if(time_3s_road_b='1') then    --checking if delay of 3 seconds has occured before turning the traffic on the high_road green again
     next_state <= highway_green_road_b_red;
   elsif(sensor='0' and sec_num/=x"0")then 
    next_state<=highway_red_road_b_green;
      
    else 
     next_state <= highway_red_road_b_yellow; --remain in the same state untill counting finishes
    end if;
    when others => next_state <= highway_green_road_b_red;  -- coverage of undefined cases to return to the main state
    end case;
  end process;  
  --------------------------------------------------
--generating delays

process(clock,sec_num_reset)
 begin

   if(rising_edge(clock)) then 
	
	if(sec_num_reset='1') then
 sec_num<=x"0";
 end if;

   if(clock_finish='1') then

    if(red_light_enable='1' or yellow_light1_enable='1' or yellow_light2_enable='1') then
     sec_num <= sec_num + x"1";
     if((sec_num = x"9") and red_light_enable ='1') then 
      time_10s <= '1';
      time_3s_highway <= '0';
      time_3s_road_b <= '0';
      sec_num <= x"0";

     elsif((sec_num = x"3") and yellow_light1_enable= '1') then
      time_10s <= '0';
      time_3s_highway <= '1';
      time_3s_road_b <= '0';
      sec_num <= x"0";

     elsif((sec_num = x"3") and yellow_light2_enable= '1') then
      time_10s <= '0';
      time_3s_highway <= '0';
      time_3s_road_b <= '1';
      sec_num <= x"0";

     else --general case with no delays
      time_10s <= '0';
      time_3s_highway <= '0';
      time_3s_road_b <= '0';
     end if;
    end if;
   end if;
  end if;
end process;
 ---------------------------------------------------------------------
process(clock)
 begin
  if(rising_edge(clock)) then 
   time_1s <= time_1s + x"0000001";
   if(time_1s >= x"2FAF080") then 
    time_1s <= x"0000000";
   end if;
  end if;
end process;
clock_finish <= '1' when time_1s = x"2FAF080" else '0'; 
  process(sec_num)
    begin
      case sec_num is
      when "0000" => LED_out <= "11000000"; -- "0"     
      when "0001" => LED_out <= "11111001"; -- "1" 
      when "0010" => LED_out <= "10100100"; -- "2" 
      when "0011" => LED_out <= "10110000"; -- "3" 
      when "0100" => LED_out <= "10011001"; -- "4" 
      when "0101" => LED_out <= "10010010"; -- "5" 
      when "0110" => LED_out <= "10000010"; -- "6" 
      when "0111" => LED_out <= "11111000"; -- "7" 
      when "1000" => LED_out <= "10000000"; -- "8"     
      when "1001" => LED_out <= "10010000"; -- "9" 
      when others =>LED_out    <="11111111";   
    end case;
  end process;
end smart_traffic_arc;



----------------------------------------------------------------------------

