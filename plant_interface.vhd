package plant_interface_types is
  type plant_interface_task is (encrypt, decrypt, rng);
end plant_interface_types;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.plant_interface_types.all;
use work.modexp_triple_M_types.all;

entity plant_interface is

  generic (
    -- Should be multiple of 16
    constant key_length : natural;
    constant N2 : unsigned(2047 downto 0);
    constant N2_dash : unsigned(15 downto 0);
    constant N_mont : unsigned(2047 downto 0);
    constant N_plus_1_mont : unsigned(2047 downto 0);
    constant N2_plus_2 : unsigned(2047 downto 0);
    constant N2_plus_2_dash : unsigned(15 downto 0);
    constant N : unsigned(2047 downto 0);
    constant N_dash : unsigned(15 downto 0);
    constant random_seed : unsigned(2047 downto 0);
    constant lambda : unsigned(2047 downto 0);
    constant N_inv_R_mont : unsigned(2047 downto 0);
    constant mu_mont : unsigned(2047 downto 0);
    constant R2_mod_N2 : unsigned(2047 downto 0);
    constant R_mod_N2 : unsigned(2047 downto 0)
  );

  port (
    clk             : in  std_logic;
    start           : in  std_logic;
    task            : in  plant_interface_task;
    data_in         : in  unsigned(key_length * 2 + 15 downto 0);
    done            : out std_logic;
    data_out        : out unsigned(key_length * 2 + 15 downto 0)
  );

end plant_interface;

architecture montencrypter of plant_interface is

  component modexp_triple_M
    generic (
      constant N2_length : natural;
      constant N2 : unsigned(2047 downto 0);
      constant N2_dash : unsigned(15 downto 0);
      constant N2_plus_2 : unsigned(2047 downto 0);
      constant N2_plus_2_dash : unsigned(15 downto 0);
      constant N : unsigned(2047 downto 0);
      constant N_dash : unsigned(15 downto 0);
      constant R_mod_N2 : unsigned(2047 downto 0)
    );
    port (
      clk          : in  std_logic;
      start        : in  std_logic;
      task         : in  modexp_triple_M_task;
      base_in      : in  unsigned(key_length * 2 + 15 downto 0);
      exponent     : in  unsigned(key_length * 2 + 15 downto 0);
      done         : out std_logic;
      power        : out unsigned(key_length * 2 + 15 downto 0)
    );
  end component;

  -- Declare I/O registers
  signal task_reg : plant_interface_task := encrypt;
  signal exp_task : modexp_triple_M_task := modexp_exp_N2;
  signal input_reg, exp_base, exp_exponent, enc_base, enc_exponent, dec_base, dec_exponent, exp_out : unsigned(key_length * 2 + 15 downto 0) := (others => '0');
  signal random : unsigned(key_length * 2 + 15 downto 0) := resize(random_seed, key_length * 2 + 16);
  signal exp_start, exp_done, first_iteration, last_iteration : std_logic := '0';
  signal counter : natural range 0 to 5 := 0;

begin

  -- Set output signals
  done <= exp_done and last_iteration;
  data_out <= exp_out;

  -- Set internal signals
  exp : modexp_triple_M
  generic map(
    N2_length => key_length * 2,
    N2 => N2,
    N2_dash => N2_dash,
    N2_plus_2 => N2_plus_2,
    N2_plus_2_dash => N2_plus_2_dash,
    N => N,
    N_dash => N_dash,
    R_mod_N2 => R_mod_N2
  )
  port map (
    clk => clk,
    start => exp_start,
    task => exp_task,
    base_in => exp_base,
    exponent => exp_exponent,
    done => exp_done,
    power => exp_out
  );
  exp_task <= modexp_exp_N2 when counter = 0 and task_reg /= encrypt else
              modexp_mult_N2 when counter = 0 or counter = 1 or (counter = 2 and task_reg = encrypt) else
              modexp_mult_N2_plus_2 when counter = 2 or counter = 3 else
              modexp_mult_N;
  -- Select data inputs to modexp based on the task
  exp_base <= enc_base when task_reg = encrypt else
              dec_base;
  exp_exponent <= enc_exponent when task_reg = encrypt else
                  dec_exponent when task_reg = decrypt else
                  resize(N, key_length * 2 + 16);

  enc_base <= N_mont(key_length * 2 + 15 downto 0) when counter = 0 else
              R2_mod_N2(key_length * 2 + 15 downto 0) when counter = 1 else
              random;
  enc_exponent <= input_reg when counter = 0 else
                  exp_out + 1 when counter = 1 else
                  exp_out;

  dec_base <= input_reg when counter = 0 else
              exp_out - 1 when counter = 2 else
              exp_out;
  dec_exponent <= lambda(key_length * 2 + 15 downto 0) when counter = 0 else
                  to_unsigned(1, key_length * 2 + 16) when counter = 1 or counter = 3 else
                  N_inv_R_mont(key_length * 2 + 15 downto 0) when counter = 2 else
                  mu_mont(key_length * 2 + 15 downto 0);

  last_iteration <= '1' when (counter = 3 and task_reg = encrypt) or
                             (counter = 5 and task_reg = decrypt) or
                             (counter = 1 and task_reg = rng) else
                    '0';
  exp_start <= first_iteration or (exp_done and not last_iteration);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        -- Update input registers and counter, start baseloop for the first time
        input_reg <= data_in;
        counter <= 0;
        first_iteration <= '1';
        task_reg <= task;
      elsif (exp_start = '1') then
        -- Increment counter
        counter <= counter + 1;
        if (first_iteration = '1') then
          first_iteration <= '0';
        end if;
      end if;
      if (task_reg = rng and exp_done = '1' and last_iteration = '1') then
        random <= exp_out;
      end if;
    end if;
  end process;

end montencrypter;