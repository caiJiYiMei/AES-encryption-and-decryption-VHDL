library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;  
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity encrypt_128_opt is
	generic (
		key_len: integer :=128;
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
end encrypt_128_opt;

architecture opt_128 of encrypt_128_opt is
    type op_code is array(0 to 10) of std_logic_vector(3 downto 0);
    constant operation_code : op_code := 
    ("0001", "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1101");

    signal op_load, op_out, sub_bytes, shift_rows, mix_column, add_keys, key_exp: std_logic := '0';
    signal round_number: integer range 0 to 15 := 0;

    type STATE is (INIT, OPER);
    signal present_state, next_state: STATE := INIT;
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
    			if round_number = 0 and d_run = '1' then
    				next_state <= OPER;
    				op_load <= '1';
    				op_out <= '0';
                    sub_bytes <= '0';
                    shift_rows <= '0';
                    mix_column <= '0';
                    add_keys   <= '0';
                    key_exp    <= '0';
    			else
    				next_state <= INIT;
    				op_load <= '0';
    				op_out <= '0';
    				sub_bytes <= '0';
                    shift_rows <= '0';
                    mix_column <= '0';
                    add_keys   <= '0';
                    key_exp    <= '0';
    			end if;
    		when  OPER =>
    			if round_number = 11 then
                    next_state <= INIT;
                    op_out <= '1';
                    op_load <= '0';
                    sub_bytes <= '0';
                    shift_rows <= '0';
                    mix_column <= '0';
                    add_keys   <= '0';
                    key_exp    <= '0';
                else
					op_load <= '0';
					op_out  <= '0';
					sub_bytes <= operation_code(round_number)(3);
					shift_rows <= operation_code(round_number)(2);
					mix_column <= operation_code(round_number)(1);
					add_keys   <= operation_code(round_number)(0);
					key_exp    <= '1';
                    next_state <= OPER;
                end if;
        end case;
    end process;
    
	process(d_clock)
	variable text_tmp:  std_logic_vector(text_len-1 downto 0) := conv_std_logic_vector(0, text_len);	--In column order
	variable tmp1: std_logic_vector(31 downto 0) := conv_std_logic_vector(0, 32);
	variable tmp2: std_logic_vector(31 downto 0) := conv_std_logic_vector(0, 32);
	variable tmp3: std_logic_vector(31 downto 0) := conv_std_logic_vector(0, 32);
	variable tmp4: std_logic_vector(31 downto 0) := conv_std_logic_vector(0, 32);
	variable tmp5: std_logic_vector(31 downto 0) := conv_std_logic_vector(0, 32);
	variable key_tmp: std_logic_vector(key_len-1 downto 0) := conv_std_logic_vector(0, key_len);type matrix_16 is array(0 to 15, 0 to 15) of std_logic_vector(7 downto 0);
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
    
    type vector_nr is array(0 to 9) of std_logic_vector(7 downto 0);
    constant RCON : vector_nr := (x"01",x"02",x"04",x"08",x"10",x"20",x"40",x"80",x"1B",x"36"); 
	begin
		if(rising_edge(d_clock)) then

			if (op_load = '1') then
				text_tmp := input_text;
				key_tmp := key;
				d_done <= '0'; 
		    else
		        text_tmp := text_tmp;
			end if;

			if (key_exp = '1') then
				if (round_number > 0) then
					tmp1 := key_tmp(127 downto 96);
		            tmp2 := key_tmp(95 downto 64);
		            tmp3 := key_tmp(63 downto 32);
		            tmp4 := key_tmp(31 downto 0);
		            tmp5 := tmp4(23 downto 0) & tmp4(31 downto 24); 									--Left shift, Rot word
		            tmp5 := sbox(conv_integer(tmp5(31 downto 28)),conv_integer(tmp5(27 downto 24)))& 	--Subword
		                    sbox(conv_integer(tmp5(23 downto 20)),conv_integer(tmp5(19 downto 16)))& 
		                    sbox(conv_integer(tmp5(15 downto 12)),conv_integer(tmp5(11 downto 8))) & 
		                    sbox(conv_integer(tmp5(7 downto 4)),conv_integer(tmp5(3 downto 0)));
		            tmp5 := tmp5 xor (RCON(round_number-1) & "000000000000000000000000");				--Xored with rcon.
		            tmp1 := tmp5 xor tmp1;
		            tmp2 := tmp2 xor tmp1;
		            tmp3 := tmp3 xor tmp2;
		            tmp4 := tmp4 xor tmp3;
		            key_tmp := tmp1 & tmp2 & tmp3 & tmp4;
		       	end if;
			end if;

			if (sub_bytes = '1') then
				text_tmp := 
				sbox(conv_integer(text_tmp(127 downto 124)),conv_integer(text_tmp(123 downto 120)))& 
				sbox(conv_integer(text_tmp(119 downto 116)),conv_integer(text_tmp(115 downto 112)))& 
				sbox(conv_integer(text_tmp(111 downto 108)),conv_integer(text_tmp(107 downto 104)))& 
				sbox(conv_integer(text_tmp(103 downto 100)),conv_integer(text_tmp(99 downto 96)))& 
				sbox(conv_integer(text_tmp(95 downto 92)),conv_integer(text_tmp(91 downto 88)))& 
				sbox(conv_integer(text_tmp(87 downto 84)),conv_integer(text_tmp(83 downto 80)))& 
				sbox(conv_integer(text_tmp(79 downto 76)),conv_integer(text_tmp(75 downto 72)))& 
				sbox(conv_integer(text_tmp(71 downto 68)),conv_integer(text_tmp(67 downto 64)))& 
				sbox(conv_integer(text_tmp(63 downto 60)),conv_integer(text_tmp(59 downto 56)))& 
				sbox(conv_integer(text_tmp(55 downto 52)),conv_integer(text_tmp(51 downto 48)))& 
				sbox(conv_integer(text_tmp(47 downto 44)),conv_integer(text_tmp(43 downto 40)))& 
				sbox(conv_integer(text_tmp(39 downto 36)),conv_integer(text_tmp(35 downto 32)))& 
				sbox(conv_integer(text_tmp(31 downto 28)),conv_integer(text_tmp(27 downto 24)))& 
				sbox(conv_integer(text_tmp(23 downto 20)),conv_integer(text_tmp(19 downto 16)))& 
				sbox(conv_integer(text_tmp(15 downto 12)),conv_integer(text_tmp(11 downto 8))) & 
				sbox(conv_integer(text_tmp(7 downto 4)),conv_integer(text_tmp(3 downto 0)));
				d_done <= '0';	
			else
				text_tmp := text_tmp;
			end if;

			if (shift_rows = '1') then
				text_tmp := text_tmp(127 downto 120) & text_tmp(87 downto 80) & text_tmp(47 downto 40) & text_tmp(7 downto 0) & text_tmp(95 downto 88) & text_tmp(55 downto 48) & text_tmp(15 downto 8) & text_tmp(103 downto 96) &
							  text_tmp(63 downto 56) & text_tmp(23 downto 16) & text_tmp(111 downto 104) & text_tmp(71 downto 64) & text_tmp(31 downto 24) & text_tmp(119 downto 112) & text_tmp(79 downto 72) & text_tmp(39 downto 32);
				d_done <= '0';
			else
				text_tmp :=text_tmp;
			end if;

			if (mix_column = '1') then
				text_tmp := (((text_tmp(126 downto 120) & '0') xor ("000"&text_tmp(127)&text_tmp(127)& '0'&text_tmp(127)&text_tmp(127))) xor (((text_tmp(118 downto 112) & '0') xor ("000"&text_tmp(119)&text_tmp(119)& '0'&text_tmp(119)&text_tmp(119))) xor text_tmp(119 downto 112)) xor text_tmp(111 downto 104) xor text_tmp(103 downto 96)) &
							  ((text_tmp(127 downto 120)) xor ((text_tmp(118 downto 112) & '0') xor ("000"&text_tmp(119)&text_tmp(119)& '0'&text_tmp(119)&text_tmp(119))) xor (((text_tmp(110 downto 104) & '0') xor ("000"&text_tmp(111)&text_tmp(111)& '0'&text_tmp(111)&text_tmp(111))) xor text_tmp(111 downto 104)) xor (text_tmp(103 downto 96))) &
							  ((text_tmp(127 downto 120)) xor (text_tmp(119 downto 112)) xor ((text_tmp(110 downto 104) & '0') xor ("000"&text_tmp(111)&text_tmp(111)& '0'&text_tmp(111)&text_tmp(111))) xor (((text_tmp(102 downto 96) & '0') xor ("000"&text_tmp(103)&text_tmp(103)& '0'&text_tmp(103)&text_tmp(103))) xor text_tmp(103 downto 96))) &
							  ((((text_tmp(126 downto 120) & '0') xor ("000"&text_tmp(127)&text_tmp(127)& '0'&text_tmp(127)&text_tmp(127))) xor text_tmp(127 downto 120)) xor (text_tmp(119 downto 112)) xor (text_tmp(111 downto 104)) xor ((text_tmp(102 downto 96) & '0') xor ("000"&text_tmp(103)&text_tmp(103)& '0'&text_tmp(103)&text_tmp(103)))) &

							  (((text_tmp(94 downto 88) & '0') xor ("000"&text_tmp(95)&text_tmp(95)& '0'&text_tmp(95)&text_tmp(95))) xor (((text_tmp(86 downto 80) & '0') xor ("000"&text_tmp(87)&text_tmp(87)& '0'&text_tmp(87)&text_tmp(87))) xor text_tmp(87 downto 80)) xor text_tmp(79 downto 72) xor text_tmp(71 downto 64)) &
							  ((text_tmp(95 downto 88)) xor ((text_tmp(86 downto 80) & '0') xor ("000"&text_tmp(87)&text_tmp(87)& '0'&text_tmp(87)&text_tmp(87))) xor (((text_tmp(78 downto 72) & '0') xor ("000"&text_tmp(79)&text_tmp(79)& '0'&text_tmp(79)&text_tmp(79))) xor text_tmp(79 downto 72)) xor (text_tmp(71 downto 64))) &
							  ((text_tmp(95 downto 88)) xor (text_tmp(87 downto 80)) xor ((text_tmp(78 downto 72) & '0') xor ("000"&text_tmp(79)&text_tmp(79)& '0'&text_tmp(79)&text_tmp(79))) xor (((text_tmp(70 downto 64) & '0') xor ("000"&text_tmp(71)&text_tmp(71)& '0'&text_tmp(71)&text_tmp(71))) xor text_tmp(71 downto 64))) &
							  ((((text_tmp(94 downto 88) & '0') xor ("000"&text_tmp(95)&text_tmp(95)& '0'&text_tmp(95)&text_tmp(95))) xor text_tmp(95 downto 88)) xor (text_tmp(87 downto 80)) xor (text_tmp(79 downto 72)) xor ((text_tmp(70 downto 64) & '0') xor ("000"&text_tmp(71)&text_tmp(71)& '0'&text_tmp(71)&text_tmp(71)))) &

							  (((text_tmp(62 downto 56) & '0') xor ("000"&text_tmp(63)&text_tmp(63)& '0'&text_tmp(63)&text_tmp(63))) xor (((text_tmp(54 downto 48) & '0') xor ("000"&text_tmp(55)&text_tmp(55)& '0'&text_tmp(55)&text_tmp(55))) xor text_tmp(55 downto 48)) xor text_tmp(47 downto 40) xor text_tmp(39 downto 32)) &
							  ((text_tmp(63 downto 56)) xor ((text_tmp(54 downto 48) & '0') xor ("000"&text_tmp(55)&text_tmp(55)& '0'&text_tmp(55)&text_tmp(55))) xor (((text_tmp(46 downto 40) & '0') xor ("000"&text_tmp(47)&text_tmp(47)& '0'&text_tmp(47)&text_tmp(47))) xor text_tmp(47 downto 40)) xor (text_tmp(39 downto 32))) &
							  ((text_tmp(63 downto 56)) xor (text_tmp(55 downto 48)) xor ((text_tmp(46 downto 40) & '0') xor ("000"&text_tmp(47)&text_tmp(47)& '0'&text_tmp(47)&text_tmp(47))) xor (((text_tmp(38 downto 32) & '0') xor ("000"&text_tmp(39)&text_tmp(39)& '0'&text_tmp(39)&text_tmp(39))) xor text_tmp(39 downto 32))) &
							  ((((text_tmp(62 downto 56) & '0') xor ("000"&text_tmp(63)&text_tmp(63)& '0'&text_tmp(63)&text_tmp(63))) xor text_tmp(63 downto 56)) xor (text_tmp(55 downto 48)) xor (text_tmp(47 downto 40)) xor ((text_tmp(38 downto 32) & '0') xor ("000"&text_tmp(39)&text_tmp(39)& '0'&text_tmp(39)&text_tmp(39)))) &

							  (((text_tmp(30 downto 24) & '0') xor ("000"&text_tmp(31)&text_tmp(31)& '0'&text_tmp(31)&text_tmp(31))) xor (((text_tmp(22 downto 16) & '0') xor ("000"&text_tmp(23)&text_tmp(23)& '0'&text_tmp(23)&text_tmp(23))) xor text_tmp(23 downto 16)) xor text_tmp(15 downto 8) xor text_tmp(7 downto 0)) &
							  ((text_tmp(31 downto 24)) xor ((text_tmp(22 downto 16) & '0') xor ("000"&text_tmp(23)&text_tmp(23)& '0'&text_tmp(23)&text_tmp(23))) xor (((text_tmp(14 downto 8) & '0') xor ("000"&text_tmp(15)&text_tmp(15)& '0'&text_tmp(15)&text_tmp(15))) xor text_tmp(15 downto 8)) xor (text_tmp(7 downto 0))) &
							  ((text_tmp(31 downto 24)) xor (text_tmp(23 downto 16)) xor ((text_tmp(14 downto 8) & '0') xor ("000"&text_tmp(15)&text_tmp(15)& '0'&text_tmp(15)&text_tmp(15))) xor (((text_tmp(6 downto 0) & '0') xor ("000"&text_tmp(7)&text_tmp(7)& '0'&text_tmp(7)&text_tmp(7))) xor text_tmp(7 downto 0))) &
							  ((((text_tmp(30 downto 24) & '0') xor ("000"&text_tmp(31)&text_tmp(31)& '0'&text_tmp(31)&text_tmp(31))) xor text_tmp(31 downto 24)) xor (text_tmp(23 downto 16)) xor (text_tmp(15 downto 8)) xor ((text_tmp(6 downto 0) & '0') xor ("000"&text_tmp(7)&text_tmp(7)& '0'&text_tmp(7)&text_tmp(7))));
				d_done <= '0';
			end if;

			if (add_keys = '1') then
				text_tmp := text_tmp xor key_tmp;
				d_done <= '0';
				round_number <= round_number + 1;
			else
				text_tmp := text_tmp;
			end if;

			if (op_out = '1') then
				output_text <= text_tmp;
				d_done <= '1';
				round_number <= 0;
			else
			    text_tmp := text_tmp;
			end if;
		end if;
	end process;
end  opt_128;