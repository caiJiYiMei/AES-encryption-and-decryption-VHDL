library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;  
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity decrypt_128 is
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
end decrypt_128;

architecture decryption_128 of decrypt_128 is
    type op_code is array(0 to 10) of std_logic_vector(3 downto 0);
    constant operation_code : op_code := 
    ("1110", "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1111", "1111", "0010");

    type matrix_16 is array(0 to 15, 0 to 15) of std_logic_vector(7 downto 0);
    constant sbox : matrix_16 :=  
		((x"52", x"09", x"6a", x"d5", x"30", x"36", x"a5", x"38", x"bf", x"40", x"a3", x"9e", x"81", x"f3", x"d7", x"fb"), -- 0
    (x"7c", x"e3", x"39", x"82", x"9b", x"2f", x"ff", x"87", x"34", x"8e", x"43", x"44", x"c4", x"de", x"e9", x"cb"), --1
    (x"54", x"7b", x"94", x"32", x"a6", x"c2", x"23", x"3d", x"ee", x"4c", x"95", x"0b", x"42", x"fa", x"c3", x"4e"), -- 2
    (x"08", x"2e", x"a1", x"66", x"28", x"d9", x"24", x"b2", x"76", x"5b", x"a2", x"49", x"6d", x"8b", x"d1", x"25"), -- 3
    (x"72", x"f8", x"f6", x"64", x"86", x"68", x"98", x"16", x"d4", x"a4", x"5c", x"cc", x"5d", x"65", x"b6", x"92"), -- 4
    (x"6c", x"70", x"48", x"50", x"fd", x"ed", x"b9", x"da", x"5e", x"15", x"46", x"57", x"a7", x"8d", x"9d", x"84"), -- 5
    (x"90", x"d8", x"ab", x"00", x"8c", x"bc", x"d3", x"0a", x"f7", x"e4", x"58", x"05", x"b8", x"b3", x"45", x"06"), -- 6
    (x"d0", x"2c", x"1e", x"8f", x"ca", x"3f", x"0f", x"02", x"c1", x"af", x"bd", x"03", x"01", x"13", x"8a", x"6b"), -- 7
    (x"3a", x"91", x"11", x"41", x"4f", x"67", x"dc", x"ea", x"97", x"f2", x"cf", x"ce", x"f0", x"b4", x"e6", x"73"), -- 8
    (x"96", x"ac", x"74", x"22", x"e7", x"ad", x"35", x"85", x"e2", x"f9", x"37", x"e8", x"1c", x"75", x"df", x"6e"), -- 9
    (x"47", x"f1", x"1a", x"71", x"1d", x"29", x"c5", x"89", x"6f", x"b7", x"62", x"0e", x"aa", x"18", x"be", x"1b"), -- a
    (x"fc", x"56", x"3e", x"4b", x"c6", x"d2", x"79", x"20", x"9a", x"db", x"c0", x"fe", x"78", x"cd", x"5a", x"f4"), -- b
    (x"1f", x"dd", x"a8", x"33", x"88", x"07", x"c7", x"31", x"b1", x"12", x"10", x"59", x"27", x"80", x"ec", x"5f"), -- c
    (x"60", x"51", x"7f", x"a9", x"19", x"b5", x"4a", x"0d", x"2d", x"e5", x"7a", x"9f", x"93", x"c9", x"9c", x"ef"), -- d
    (x"a0", x"e0", x"3b", x"4d", x"ae", x"2a", x"f5", x"b0", x"c8", x"eb", x"bb", x"3c", x"83", x"53", x"99", x"61"), -- e
    (x"17", x"2b", x"04", x"7e", x"ba", x"77", x"d6", x"26", x"e1", x"69", x"14", x"63", x"55", x"21", x"0c", x"7d"));-- f
    
	
	constant nsbox : matrix_16 :=  
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

	type matrix_4 is array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
	constant mix_matrix : matrix_4 := 
	((x"0E", x"0B", x"0D", x"09"),
	 (x"09", x"0E", x"0B", x"0D"),
	 (x"0D", x"09", x"0E", x"0B"),
	 (x"0B", x"0D", x"09", x"0E")); 

    signal op_load, op_out, sub_bytes, shift_rows, mix_column, add_keys, key_exp: std_logic := '0';
    signal round_number: integer range -16 to 15 := 13;

    type STATE is (INIT, KEYEXP, OPER);
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
    			if round_number = 13 and d_run = '1' then
    				next_state <= KEYEXP;
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
    		when KEYEXP =>
    			next_state <= OPER;
				op_load <= '0';
				op_out <= '0';
				sub_bytes <= '0';
                shift_rows <= '0';
                mix_column <= '0';
                add_keys   <= '0';
                key_exp    <= '1';
    		when  OPER =>
    			if round_number = -1 then
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
					shift_rows <= operation_code(round_number)(3);
					sub_bytes <= operation_code(round_number)(2);
					add_keys <= operation_code(round_number)(1);
					mix_column   <= operation_code(round_number)(0);
					key_exp    <= '0';
                    next_state <= OPER;
                end if;
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
    	variable text_tmp:  std_logic_vector(text_len-1 downto 0) := conv_std_logic_vector(0, text_len);	--In column order
    	variable key_tmp: std_logic_vector(key_len-1 downto 0) := conv_std_logic_vector(0, key_len);
    	variable temp: std_logic_vector(31 downto 0):= conv_std_logic_vector(0, 32);
    	variable i: integer range 0 to 4*(nr+1) := nk;
    	type vector_nr is array(0 to 9) of std_logic_vector(7 downto 0);
    	constant RCON : vector_nr := (x"01",x"02",x"04",x"08",x"10",x"20",x"40",x"80",x"1B",x"36"); 
    	type key_word is array(0 to 4*(nr+1)-1) of std_logic_vector(31 downto 0);
        variable w: key_word;
        variable count: integer range 0 to 7 := 0;
		variable count1: integer range 0 to 7 := 0;
		variable count2: integer range 0 to 7 := 0;
		type matrix_mix is array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
		variable mix_tmp, mix_tmp1: matrix_mix;
		variable m,n,k : integer range 0 to 3 := 0;
		variable co1: integer range 0 to 7 :=0;
		variable nbs: std_logic := '0';
		variable p, b_mix, a_mix: std_logic_vector(7 downto 0) := conv_std_logic_vector(0,8);
    begin
    	if(rising_edge(d_clock)) then

			if (op_load = '1') then
				text_tmp := input_text;
				key_tmp := key;
				d_done <= '0'; 
				round_number <= 11;
		    else
		        text_tmp := text_tmp;
			end if;

			if (key_exp = '1') then
				for count2 in 0 to nk-1 loop
					w(count2) := key_tmp((32*nk-1)-(32*count2) downto (32*nk-1-31)-(32*count2));
				end loop;
				i := nk;
				while (i < 4 * (nr + 1)) loop
					temp := w(i-1);
                    if ((i rem nk) = 0) then
                        temp := temp(23 downto 0) & temp(31 downto 24);
                        temp := 
                            nsbox(conv_integer(temp(31 downto 28)),conv_integer(temp(27 downto 24)))& 	--Subword
                            nsbox(conv_integer(temp(23 downto 20)),conv_integer(temp(19 downto 16)))& 
                            nsbox(conv_integer(temp(15 downto 12)),conv_integer(temp(11 downto 8))) & 
                            nsbox(conv_integer(temp(7 downto 4)),conv_integer(temp(3 downto 0)));
                        temp := temp xor (RCON((i/nk)-1) & "000000000000000000000000");
                    end if;
                    w(i) := temp xor w(i - nk);
                    i := i + 1;
				end loop;
				round_number <= round_number - 1;
			end if;

			--After shift row operation.
			-----------------------------------------
			-- | 127~120	| 95~88	| 63~56	| 31~24 |
			-----------------------------------------
			-- | 23~16	    |119~112| 87~80	| 55~48 |
			-----------------------------------------
			-- | 47~40	    | 15~8	|111~104| 79~72 |
			-----------------------------------------
			-- | 71~64		| 39~32 |  7~0	| 103~96|
			-----------------------------------------

			if (shift_rows = '1') then
				text_tmp := text_tmp(127 downto 120) & text_tmp(23 downto 16)   & text_tmp(47 downto 40)   & text_tmp(71 downto 64) & 
							text_tmp(95 downto 88)   & text_tmp(119 downto 112) & text_tmp(15 downto 8)    & text_tmp(39 downto 32) &
							text_tmp(63 downto 56)   & text_tmp(87 downto 80)   & text_tmp(111 downto 104) & text_tmp(7 downto 0)   &
							text_tmp(31 downto 24)   & text_tmp(55 downto 48)   & text_tmp(79 downto 72)   & text_tmp(103 downto 96);
				d_done <= '0';
			else
				text_tmp :=text_tmp;
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

			if (add_keys = '1') then
				for count1 in 0 to 3 loop
			    	key_tmp(127 - count1*32  downto 96 - count1*32) := w((round_number)*4 + count1);
		    	end loop;
				text_tmp := text_tmp xor key_tmp;
				d_done <= '0';
				round_number <= round_number - 1;
			else
				text_tmp := text_tmp;
			end if;
			--mix column matrix: 
			-- ---------------------    -----------------------------------------
			-- | 0e | 0b | 0d | 09 |	-- | 127~120	| 95~88	| 63~56	| 31~24 |
			-- --------------------- 	-----------------------------------------
			-- | 09 | 0e | 0b | 0d |	-- | 119~112	| 87~80	| 55~48	| 23~16 |
			-- ---------------------	-----------------------------------------
			-- | 0d | 09 | 0e | 0b |	-- | 111~104	| 79~72	| 47~40	| 15~8  |
			-- ---------------------	-----------------------------------------
			-- | 0b | 0d | 09 | 0e |	-- | 103~96		| 71~64	| 39~32	| 7~0   |
			-- ---------------------	-----------------------------------------

			if (mix_column = '1') then
				mix_tmp(0,0) := text_tmp(127 downto 120);
				mix_tmp(0,1) := text_tmp(95 downto 88);
				mix_tmp(0,2) := text_tmp(63 downto 56);
				mix_tmp(0,3) := text_tmp(31 downto 24);
				mix_tmp(1,0) := text_tmp(119 downto 112);
				mix_tmp(1,1) := text_tmp(87 downto 80);
				mix_tmp(1,2) := text_tmp(55 downto 48);
				mix_tmp(1,3) := text_tmp(23 downto 16);
				mix_tmp(2,0) := text_tmp(111 downto 104);
				mix_tmp(2,1) := text_tmp(79 downto 72);
				mix_tmp(2,2) := text_tmp(47 downto 40);
				mix_tmp(2,3) := text_tmp(15 downto 8);
				mix_tmp(3,0) := text_tmp(103 downto 96);
				mix_tmp(3,1) := text_tmp(71 downto 64);
				mix_tmp(3,2) := text_tmp(39 downto 32);
				mix_tmp(3,3) := text_tmp(7 downto 0);
				for m in 0 to 3 loop
					for n in 0 to 3 loop
						mix_tmp1(m,n) := "00000000";
						for k in 0 to 3 loop
							p := "00000000";
							nbs := '0';
							b_mix := mix_matrix(m,k);
							a_mix := mix_tmp(k,n);
							for co1 in 0 to 7 loop
								if ((b_mix(0) and '1') = '1') then
									p := p xor a_mix;
								end if;
								nbs := a_mix(7) and '1';
								a_mix := a_mix(6 downto 0) & '0';
								if (nbs = '1') then
									a_mix := a_mix xor "00011011";
								else
									a_mix := a_mix;
								end if;
								b_mix := '0' & b_mix(7 downto 1);
							end loop;
							mix_tmp1(m,n)  := mix_tmp1(m,n) xor p;
						end loop;		
					end loop;
				end loop;
				text_tmp(127 downto 120) := mix_tmp1(0,0);
				text_tmp(95 downto 88) := mix_tmp1(0,1);
				text_tmp(63 downto 56):=  mix_tmp1(0,2);
				text_tmp(31 downto 24) := mix_tmp1(0,3);
				text_tmp(119 downto 112) := mix_tmp1(1,0);
				text_tmp(87 downto 80) := mix_tmp1(1,1);
				text_tmp(55 downto 48) := mix_tmp1(1,2);
				text_tmp(23 downto 16) := mix_tmp1(1,3);
				text_tmp(111 downto 104) := mix_tmp1(2,0);
				text_tmp(79 downto 72) := mix_tmp1(2,1);
				text_tmp(47 downto 40) := mix_tmp1(2,2);
				text_tmp(15 downto 8) := mix_tmp1(2,3);
				text_tmp(103 downto 96) := mix_tmp1(3,0);
				text_tmp(71 downto 64) := mix_tmp1(3,1);
				text_tmp(39 downto 32) := mix_tmp1(3,2);
				text_tmp(7 downto 0) := mix_tmp1(3,3);
				d_done <= '0';
			else
				text_tmp := text_tmp;
			end if;

			if (op_out = '1') then
				output_text <= text_tmp;
				d_done <= '1';
				round_number <= 13;
			else
			    text_tmp := text_tmp;
			end if;
		end if;
    end process;
end decryption_128;
