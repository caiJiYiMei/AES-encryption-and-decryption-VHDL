library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;  
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

--Here is some instructions in order to simulate all the structure correctly:
--There are four simulation types: 128 encryption test using (128_encrypt_opt), 192 encryption test using (256_encrypt)
--								      128 decryption test using (128_decrypt),     256 encryption test using (256_encrypt)
--When testing the corresponding type you should make some change on top.vhd and testbench.vhd:
--The default simulation type is 128 encryption test using (128_encrypt_opt)
--1. Make sure which type of simulation you want to simulate.
--2. Go to the top.vhd first remove the '--' according the discription of the comment, there are usually three same assignment sentence,
--   when remove one '--' you should add '--' to another similar meaning sentence.
--3. Go to the testbench.vhd remove '--' and add '--' according the discription of each sentence.
--4. There are two simmulation process when using one you should disable another one.
--5. Modify the cycle time when testing the 128 encryption(for ranking) you should adjust the clock cycle time to 5ns, while 
--   testing another three types you should change the cycle time to 20ns and change the simulation time to 2000ns, since the 256_encrypt have a
--   different structure which need more time to run.
--6. First run the behavior simulation, in case you may forget to change some parameters and sentences. If there are some error usually this is because the 
--   dimension error just go to the corressponding sentence and fix it.
--The synthesis and post simulation of decryption and 256/192 encryption may take long time.


--Test reqiurement of 256/192 encryption and decryption module.
--1. The cycle time should be larger than 40ns.
--2. The simualtion time should be adjust to 2000ns.
--3. The input key and input key can not change when done=0, once the run become 1 they should be fixed until the module finished.

entity testbench is
end testbench;

architecture Behavioral of testbench is
	component top
		port(CLK : in STD_LOGIC;
			Run : in STD_LOGIC;
			Done : out STD_LOGIC;
			Key : in STD_LOGIC_VECTOR (127 downto 0);		    --128_encrypt_opt or 128_decrypt
			-- Key : in STD_LOGIC_VECTOR (191 downto 0);		--when testing 192 encryption
			-- Key : in STD_LOGIC_VECTOR (255 downto 0);		--when testing 256 encryption
			Input_text : in STD_LOGIC_VECTOR (127 downto 0);
			Output_text : out STD_LOGIC_VECTOR (127 downto 0)
		);
	end component;
	signal s_clk, s_done, s_run: std_logic := '0';
	signal s_input_text: std_logic_vector(127 downto 0) := conv_std_logic_vector(0, 128);
	signal s_input_key : std_logic_vector(127 downto 0) := conv_std_logic_vector(0, 128);			--128_encrypt_opt or 128_decrypt
	-- signal s_input_key : std_logic_vector(191 downto 0) := conv_std_logic_vector(0, 192);		--when testing 192 encryption
	-- signal s_input_key : std_logic_vector(255 downto 0) := conv_std_logic_vector(0, 256);		--when testing 256 encryption
	signal s_output_text: std_logic_vector(127 downto 0):= conv_std_logic_vector(0, 128);
begin
	u2: top port map (
		CLK => s_clk, Run => s_run, Done => s_done, Key => s_input_key, Input_text => s_input_text, Output_text => s_output_text
	);

	sim_clk: process
	begin
		s_clk <= '0';
		wait for 5ns;     -- When testing 128 encryption
		--wait for 20ns;  -- when testing 256/192 encryption  or 128_decrypt
		s_clk <= '1';
		wait for 5ns;     -- When testing 128 encryption
		--wait for 20ns;  -- when testing 256/192 encryption  or 128_decrypt
	end process;

--When tesing this ecnryption 128 module remove all '--' while at same time annotate the following process with '--'
--When tesing this module you need to adjust the sim_clk process with "wait for 5ns" in another word change the cycle to 10ns.
--You also need to change your simulation time to 2000ns (Not necessary)
----------------------------------Testing encryption 128 for optimization--------------------------------------------------
	sim: process
	begin
		s_run <= '0';
		wait for 200ns;
		wait for 40ns;
		s_run <= '1';
		--For optimization time and resorce  128
        s_input_key <= x"5468617473206D79204B756E67204675";
        s_input_text <= x"54776F204F6E65204E696E652054776F";
        wait for 12ns;
        s_run <= '0';
        s_input_key <= conv_std_logic_vector(0, 128);
        s_input_text <= x"00000000000000000000000000000000";
		wait for 1200ns;
	end process;
--------------------------------------------------------------------------------------------------------------------------

--When tesing this 192/256 encryption and 128 decryption module remove '--' 
--according your purpose while at same time annotate the above process with '--'
--When tesing this module you need to adjust the sim_clk process with "wait for 20ns" in another word change the cycle to 40ns. 
--You also need to change your simulation time to 2000ns
---------------------------------Tesing 192/256 encryption and 128 decryption------------------------------------------------------
	--sim: process
	--begin
	--	s_run <= '0';
	--	wait for 200ns;
	--	wait for 40ns;
	--	s_run <= '1';
 --       -- For encryption 192
 --       -- s_input_key <= x"000102030405060708090a0b0c0d0e0f1011121314151617";
 --       -- s_input_text <= x"00112233445566778899aabbccddeeff";
 --       -- Result: dda97ca4864cdfe06eaf70a0ec0d7191
         
 --       -- For encryption 256
 --       -- s_input_key <= x"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
 --       -- s_input_text <= x"00112233445566778899aabbccddeeff";
 --       --result: 8ea2b7ca516745bfeafc49904b496089

	--	--For decryption 128
 --       s_input_key <= x"000102030405060708090a0b0c0d0e0f";
 --       s_input_text <= x"69c4e0d86a7b0430d8cdb78070b4c55a";
 --       -- result: 00112233445566778899aabbccddeeff
 --       wait for 100ns;
 --       s_run <= '0';
	--	wait for 1200ns;
	--end process;

---------------------------------------------------------------------------------------------------------------------------------------
end Behavioral;