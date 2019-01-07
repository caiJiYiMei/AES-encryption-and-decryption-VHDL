library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;  
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity encrypt_256 is
	generic (
		key_len: integer :=256;
		text_len: integer := 128;
		nr: integer := 10;
		nk: integer := 4
	);
	port (
			d_clock : in std_logic;
			d_run: in std_logic;
			d_done: out std_logic := '1';
			key: in std_logic_vector(key_len-1 downto 0);
			input_text: in std_logic_vector(text_len-1 downto 0);
			output_text: out std_logic_vector(text_len-1 downto 0) := conv_std_logic_vector(0,text_len)
		);
end encrypt_256;

architecture encryption_256 of encrypt_256 is
	type matrix_16 is array(0 to 15, 0 to 15) of std_logic_vector(7 downto 0);
	constant sbox : matrix_16 :=  
	((x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76"),
    (x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0"),
    (x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15"),
    (x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75"),
    (x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84"),
    (x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf"),
    (x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8"),
    (x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2"),
    (x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73"), 
    (x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db"), 
    (x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79"), 
    (x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08"),
    (x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a"), 
    (x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e"), 
    (x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df"), 
    (x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16"));

	type vector_nr is array(0 to 13) of std_logic_vector(7 downto 0);
    constant RCON : vector_nr := (x"01",x"02",x"04",x"08",x"10",x"20",x"40",x"80",x"1B",x"36",x"D8", x"AB", x"4D", x"9A"); 

    --Updata at Key expansion, using at calculator.
   

    --Using at FSM
    signal op_cipher: std_logic_vector(3 downto 0) := "1000";
    signal op_load:   std_logic_vector(1 downto 0) := "00";
    signal op_out: std_logic_vector(1 downto 0) := "00";
    type STATE is (INIT, SUBSTITUDE, SHIFT, MIX, ADDR);
    signal present_state, next_state: STATE := INIT;

    --Using at Key expansion;
    signal key_state: std_logic_vector(127 downto 0) := conv_std_logic_vector(0, 128);
    signal key_buffer: std_logic_vector(32*nk-1 downto 0) := conv_std_logic_vector(0, 32*nk);

    --Using at Calculator;
    signal plain_text: std_logic_vector(127 downto 0) := conv_std_logic_vector(0, 128);	--In column order
    signal round_number: integer range 0 to 15:= 0;
   
begin
    process(d_clock) 
    begin
    	if (rising_edge(d_clock)) then
    		present_state <= next_state;
    	end if;
    end process;

    process(present_state, d_run, round_number)
    begin
    	case(present_state) is
    		when INIT =>
    			op_out <= "00";
    			op_cipher <= "0000";
    			if round_number = 0 and d_run = '1' then
    				next_state <= ADDR;
    				op_load <= "01";
    			else
    				next_state <= INIT;
    				op_load <= "00";
    			end if;
    		when SUBSTITUDE =>
    			op_load <= "00";
    			op_out <= "00";
    			op_cipher <= "1000";
    			if round_number = nr then
                    next_state <= INIT;
                  	op_out <= "01";
                else
                    op_out <= "00";
                    next_state <= SHIFT;
                end if;
    		when SHIFT =>
    			op_load <= "00";
    			op_out <= "00";
    			op_cipher <= "0100";
    			if round_number = nr then
    				next_state <= ADDR;
    			else
    				next_state <= MIX;
    			end if;
    		when MIX =>
    			op_load <= "00";
    			op_out <= "00";
    			op_cipher <= "0010";
    			next_state <= ADDR;
    		when ADDR =>
    			op_load <= "00";
    			op_out <= "00";
    			op_cipher <= "0001";
                next_state <= SUBSTITUDE;           
    		when others =>
    			op_load <= "00";
    			op_out <= "00";
    			op_cipher <= "0000";
    	end case;
    end process;

	--plaintext structure.
	-----------------------------------------
	-- | 127~120	| 95~88	| 63~56	| 31~24 |
	-----------------------------------------
	-- | 119~112	| 87~80	| 55~48	| 23~16 |
	-----------------------------------------
	-- | 111~104	| 79~72	| 47~40	| 15~8  |
	-----------------------------------------
	-- | 103~96		| 71~64	| 39~32	| 7~0   |
	-----------------------------------------
	process(d_clock)		
	begin
		if(rising_edge(d_clock)) then
			if (op_load = "01") then
				plain_text <= input_text;
				key_buffer <= key;
				d_done <= '0';
				round_number <= 0;
			elsif (op_cipher = "1000") then							--Substitude bytes module.
				plain_text <= 
				sbox(conv_integer(plain_text(127 downto 124)),conv_integer(plain_text(123 downto 120)))& 
				sbox(conv_integer(plain_text(119 downto 116)),conv_integer(plain_text(115 downto 112)))& 
				sbox(conv_integer(plain_text(111 downto 108)),conv_integer(plain_text(107 downto 104)))& 
				sbox(conv_integer(plain_text(103 downto 100)),conv_integer(plain_text(99 downto 96)))& 
				sbox(conv_integer(plain_text(95 downto 92)),conv_integer(plain_text(91 downto 88)))& 
				sbox(conv_integer(plain_text(87 downto 84)),conv_integer(plain_text(83 downto 80)))& 
				sbox(conv_integer(plain_text(79 downto 76)),conv_integer(plain_text(75 downto 72)))& 
				sbox(conv_integer(plain_text(71 downto 68)),conv_integer(plain_text(67 downto 64)))& 
				sbox(conv_integer(plain_text(63 downto 60)),conv_integer(plain_text(59 downto 56)))& 
				sbox(conv_integer(plain_text(55 downto 52)),conv_integer(plain_text(51 downto 48)))& 
				sbox(conv_integer(plain_text(47 downto 44)),conv_integer(plain_text(43 downto 40)))& 
				sbox(conv_integer(plain_text(39 downto 36)),conv_integer(plain_text(35 downto 32)))& 
				sbox(conv_integer(plain_text(31 downto 28)),conv_integer(plain_text(27 downto 24)))& 
				sbox(conv_integer(plain_text(23 downto 20)),conv_integer(plain_text(19 downto 16)))& 
				sbox(conv_integer(plain_text(15 downto 12)),conv_integer(plain_text(11 downto 8))) & 
				sbox(conv_integer(plain_text(7 downto 4)),conv_integer(plain_text(3 downto 0)));
                round_number <= round_number + 1;
			--After shift row operation.
			-----------------------------------------
			-- | 127~120	| 95~88	| 63~56	| 31~24 |
			-----------------------------------------
			-- | 87~80	    | 55~48	| 23~16	|119~112|
			-----------------------------------------
			-- | 47~40	    | 15~8	|111~104| 79~72 |
			-----------------------------------------
			-- | 7~0		| 103~96| 71~64	| 39~32 |
			-----------------------------------------
			elsif (op_cipher = "0100") then
				plain_text <= plain_text(127 downto 120) & plain_text(87 downto 80) & plain_text(47 downto 40) & plain_text(7 downto 0) & plain_text(95 downto 88) & plain_text(55 downto 48) & plain_text(15 downto 8) & plain_text(103 downto 96) &
							  plain_text(63 downto 56) & plain_text(23 downto 16) & plain_text(111 downto 104) & plain_text(71 downto 64) & plain_text(31 downto 24) & plain_text(119 downto 112) & plain_text(79 downto 72) & plain_text(39 downto 32);
			    d_done <= '0';
			elsif (op_cipher = "0010") then
				--mix column matrix: 
				-- ---------------------    -----------------------------------------
				-- | 02 | 03 | 01 | 01 |	-- | 127~120	| 95~88	| 63~56	| 31~24 |
				-- --------------------- 	-----------------------------------------
				-- | 01 | 02 | 03 | 01 |	-- | 119~112	| 87~80	| 55~48	| 23~16 |
				-- ---------------------	-----------------------------------------
				-- | 01 | 01 | 02 | 03 |	-- | 111~104	| 79~72	| 47~40	| 15~8  |
				-- ---------------------	-----------------------------------------
				-- | 03 | 01 | 01 | 02 |	-- | 103~96		| 71~64	| 39~32	| 7~0   |
				-- ---------------------	-----------------------------------------

				plain_text <= (((plain_text(126 downto 120) & '0') xor ("000"&plain_text(127)&plain_text(127)& '0'&plain_text(127)&plain_text(127))) xor (((plain_text(118 downto 112) & '0') xor ("000"&plain_text(119)&plain_text(119)& '0'&plain_text(119)&plain_text(119))) xor plain_text(119 downto 112)) xor plain_text(111 downto 104) xor plain_text(103 downto 96)) &
							  ((plain_text(127 downto 120)) xor ((plain_text(118 downto 112) & '0') xor ("000"&plain_text(119)&plain_text(119)& '0'&plain_text(119)&plain_text(119))) xor (((plain_text(110 downto 104) & '0') xor ("000"&plain_text(111)&plain_text(111)& '0'&plain_text(111)&plain_text(111))) xor plain_text(111 downto 104)) xor (plain_text(103 downto 96))) &
							  ((plain_text(127 downto 120)) xor (plain_text(119 downto 112)) xor ((plain_text(110 downto 104) & '0') xor ("000"&plain_text(111)&plain_text(111)& '0'&plain_text(111)&plain_text(111))) xor (((plain_text(102 downto 96) & '0') xor ("000"&plain_text(103)&plain_text(103)& '0'&plain_text(103)&plain_text(103))) xor plain_text(103 downto 96))) &
							  ((((plain_text(126 downto 120) & '0') xor ("000"&plain_text(127)&plain_text(127)& '0'&plain_text(127)&plain_text(127))) xor plain_text(127 downto 120)) xor (plain_text(119 downto 112)) xor (plain_text(111 downto 104)) xor ((plain_text(102 downto 96) & '0') xor ("000"&plain_text(103)&plain_text(103)& '0'&plain_text(103)&plain_text(103)))) &

							  (((plain_text(94 downto 88) & '0') xor ("000"&plain_text(95)&plain_text(95)& '0'&plain_text(95)&plain_text(95))) xor (((plain_text(86 downto 80) & '0') xor ("000"&plain_text(87)&plain_text(87)& '0'&plain_text(87)&plain_text(87))) xor plain_text(87 downto 80)) xor plain_text(79 downto 72) xor plain_text(71 downto 64)) &
							  ((plain_text(95 downto 88)) xor ((plain_text(86 downto 80) & '0') xor ("000"&plain_text(87)&plain_text(87)& '0'&plain_text(87)&plain_text(87))) xor (((plain_text(78 downto 72) & '0') xor ("000"&plain_text(79)&plain_text(79)& '0'&plain_text(79)&plain_text(79))) xor plain_text(79 downto 72)) xor (plain_text(71 downto 64))) &
							  ((plain_text(95 downto 88)) xor (plain_text(87 downto 80)) xor ((plain_text(78 downto 72) & '0') xor ("000"&plain_text(79)&plain_text(79)& '0'&plain_text(79)&plain_text(79))) xor (((plain_text(70 downto 64) & '0') xor ("000"&plain_text(71)&plain_text(71)& '0'&plain_text(71)&plain_text(71))) xor plain_text(71 downto 64))) &
							  ((((plain_text(94 downto 88) & '0') xor ("000"&plain_text(95)&plain_text(95)& '0'&plain_text(95)&plain_text(95))) xor plain_text(95 downto 88)) xor (plain_text(87 downto 80)) xor (plain_text(79 downto 72)) xor ((plain_text(70 downto 64) & '0') xor ("000"&plain_text(71)&plain_text(71)& '0'&plain_text(71)&plain_text(71)))) &

							  (((plain_text(62 downto 56) & '0') xor ("000"&plain_text(63)&plain_text(63)& '0'&plain_text(63)&plain_text(63))) xor (((plain_text(54 downto 48) & '0') xor ("000"&plain_text(55)&plain_text(55)& '0'&plain_text(55)&plain_text(55))) xor plain_text(55 downto 48)) xor plain_text(47 downto 40) xor plain_text(39 downto 32)) &
							  ((plain_text(63 downto 56)) xor ((plain_text(54 downto 48) & '0') xor ("000"&plain_text(55)&plain_text(55)& '0'&plain_text(55)&plain_text(55))) xor (((plain_text(46 downto 40) & '0') xor ("000"&plain_text(47)&plain_text(47)& '0'&plain_text(47)&plain_text(47))) xor plain_text(47 downto 40)) xor (plain_text(39 downto 32))) &
							  ((plain_text(63 downto 56)) xor (plain_text(55 downto 48)) xor ((plain_text(46 downto 40) & '0') xor ("000"&plain_text(47)&plain_text(47)& '0'&plain_text(47)&plain_text(47))) xor (((plain_text(38 downto 32) & '0') xor ("000"&plain_text(39)&plain_text(39)& '0'&plain_text(39)&plain_text(39))) xor plain_text(39 downto 32))) &
							  ((((plain_text(62 downto 56) & '0') xor ("000"&plain_text(63)&plain_text(63)& '0'&plain_text(63)&plain_text(63))) xor plain_text(63 downto 56)) xor (plain_text(55 downto 48)) xor (plain_text(47 downto 40)) xor ((plain_text(38 downto 32) & '0') xor ("000"&plain_text(39)&plain_text(39)& '0'&plain_text(39)&plain_text(39)))) &

							  (((plain_text(30 downto 24) & '0') xor ("000"&plain_text(31)&plain_text(31)& '0'&plain_text(31)&plain_text(31))) xor (((plain_text(22 downto 16) & '0') xor ("000"&plain_text(23)&plain_text(23)& '0'&plain_text(23)&plain_text(23))) xor plain_text(23 downto 16)) xor plain_text(15 downto 8) xor plain_text(7 downto 0)) &
							  ((plain_text(31 downto 24)) xor ((plain_text(22 downto 16) & '0') xor ("000"&plain_text(23)&plain_text(23)& '0'&plain_text(23)&plain_text(23))) xor (((plain_text(14 downto 8) & '0') xor ("000"&plain_text(15)&plain_text(15)& '0'&plain_text(15)&plain_text(15))) xor plain_text(15 downto 8)) xor (plain_text(7 downto 0))) &
							  ((plain_text(31 downto 24)) xor (plain_text(23 downto 16)) xor ((plain_text(14 downto 8) & '0') xor ("000"&plain_text(15)&plain_text(15)& '0'&plain_text(15)&plain_text(15))) xor (((plain_text(6 downto 0) & '0') xor ("000"&plain_text(7)&plain_text(7)& '0'&plain_text(7)&plain_text(7))) xor plain_text(7 downto 0))) &
							  ((((plain_text(30 downto 24) & '0') xor ("000"&plain_text(31)&plain_text(31)& '0'&plain_text(31)&plain_text(31))) xor plain_text(31 downto 24)) xor (plain_text(23 downto 16)) xor (plain_text(15 downto 8)) xor ((plain_text(6 downto 0) & '0') xor ("000"&plain_text(7)&plain_text(7)& '0'&plain_text(7)&plain_text(7))));
                d_done <= '0';		
			elsif (op_cipher = "0001") then
				plain_text <= plain_text xor key_state;
				d_done <= '0';
			else
			     plain_text <= plain_text;
			end if;
			if (op_out = "01") then
                 output_text <= plain_text;
                 d_done <= '1';
                 round_number <= 0;
            end if;
		end if;
	end process;

	process(d_clock)
		variable temp: std_logic_vector(31 downto 0):= conv_std_logic_vector(0, 32);
		variable temp1: std_logic_vector(31 downto 0):= conv_std_logic_vector(0, 32);
		variable i: integer range 0 to 4*(nr+1) := nk;
		variable con1: integer range 0 to 15 := 0;
		variable count: integer range 0 to 7 := 0;
		variable count1: integer range 0 to 7 := 0;
		variable count2: integer range 0 to 7 := 0;
		type key_word is array(0 to 4*(nr+1)+3) of std_logic_vector(31 downto 0);
        variable w: key_word;
	begin
		if(rising_edge(d_clock)) then
			if(round_number = 0) then
				for count2 in 0 to nk-1 loop
					w(count2) := key((32*nk-1)-(32*count2) downto (32*nk-1-31)-(32*count2));
				end loop;
				i := nk;
			elsif (round_number > con1) then
                    for count in 0 to 3 loop
                        temp := w(i-1);
                        if ((i rem nk) = 0) then
                            temp := temp(23 downto 0) & temp(31 downto 24);
                            temp := 
                                sbox(conv_integer(temp(31 downto 28)),conv_integer(temp(27 downto 24)))& 	--Subword
                                sbox(conv_integer(temp(23 downto 20)),conv_integer(temp(19 downto 16)))& 
                                sbox(conv_integer(temp(15 downto 12)),conv_integer(temp(11 downto 8))) & 
                                sbox(conv_integer(temp(7 downto 4)),conv_integer(temp(3 downto 0)));
                            temp := temp xor (RCON((i/nk) - 1) & "000000000000000000000000");
                        elsif (nk = 8 and (i rem nk) = 4) then
                            temp := 
                                sbox(conv_integer(temp(31 downto 28)),conv_integer(temp(27 downto 24)))& 	--Subword
                                sbox(conv_integer(temp(23 downto 20)),conv_integer(temp(19 downto 16)))& 
                                sbox(conv_integer(temp(15 downto 12)),conv_integer(temp(11 downto 8))) & 
                                sbox(conv_integer(temp(7 downto 4)),conv_integer(temp(3 downto 0)));
                        end if;
                        w(i) := temp xor w(i - nk);
                        i := i + 1;
                    end loop;
				con1 := con1 + 1;
				if (round_number = nr) then
                     con1 := 0;
                     i := nk;
                else
                     con1 := con1;
                     i := i;
                end if;
			end if;
			for count1 in 0 to 3 loop
			     key_state(127 - count1*32  downto 96 - count1*32) <= w(round_number*4 + count1);
		    end loop;
		end if;
	end process;
end encryption_256;