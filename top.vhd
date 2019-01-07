library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
	generic(n : INTEGER := 128);				--128_encrypt_opt or 128_decrypt
	-- generic(n: integer := 192);				--when testing 192 encryption
	-- generic(n: integer := 256);				--when testing 256 encryption
	port(CLK : in STD_LOGIC;
		Run : in STD_LOGIC;
		Done : out STD_LOGIC;
		Key : in STD_LOGIC_VECTOR (n-1 downto 0);
		Input_text : in STD_LOGIC_VECTOR (127 downto 0);
		Output_text : out STD_LOGIC_VECTOR (127 downto 0)
	);
end top;

architecture Behavioral of top is
    -- component encrypt_256					--When tesing encryption 256/192
    -- component decrypt_128					--When tesing decryption 128
	 component encrypt_128_opt				    --When tesing encryption 128
		generic (
			key_len: integer := 128;
			text_len: integer := 128;
			nr: integer := 14;
			nk: integer := 8
		);
		port (
			d_clock : in std_logic;
			d_run: in std_logic;
			d_done: out std_logic;
			key: in std_logic_vector(key_len-1 downto 0);
			input_text: in std_logic_vector(text_len-1 downto 0);
			output_text: out std_logic_vector(text_len-1 downto 0)
		);
	end component;
begin
	--When testing encryption 128
	   u1: encrypt_128_opt Generic map (key_len => 128, text_len => 128, nr => 10, nk => 4) port map (d_clock => CLK, d_run => Run, d_done => Done, key => Key, input_text => Input_text, output_text => Output_text);
    --When testting encryption 192
    -- u1: encrypt_256 Generic map (key_len => 192, text_len => 128, nr => 12, nk => 6) port map (d_clock => CLK, d_run => Run, d_done => Done, key => Key, input_text => Input_text, output_text => Output_text);
    --When testing encryption 256
    -- u1: encrypt_256 Generic map (key_len => 256, text_len => 128, nr => 14, nk => 8) port map (d_clock => CLK, d_run => Run, d_done => Done, key => Key, input_text => Input_text, output_text => Output_text);
    --When testing decryption 128
    -- u1: decrypt_128 Generic map (key_len => 128, text_len => 128, nr => 10, nk => 4) port map (d_clock => CLK, d_run => Run, d_done => Done, key => Key, input_text => Input_text, output_text => Output_text);
end Behavioral;



