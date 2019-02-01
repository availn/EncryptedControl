library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.controller_types.all;
use work.plant_interface_types.all;

entity paillier_inverted_pendulum is

  generic (
    -- Should be multiple of 16
    constant key_length : natural;
    constant data_length : natural;
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
    constant k_p_theta : unsigned(2047 downto 0);
    constant k_d_theta : unsigned(2047 downto 0);
    constant k_alpha : unsigned(2047 downto 0);
    constant neg_k_d_theta : unsigned(2047 downto 0);
    constant neg_k_d_alpha : unsigned(2047 downto 0);
    constant R2_mod_N2 : unsigned(2047 downto 0);
    constant R_mod_N2 : unsigned(2047 downto 0)
  );

  port (
    clk             : in  std_logic;
    start           : in  std_logic;
    theta           : in  unsigned(data_length - 1 downto 0);
    alpha           : in  unsigned(data_length - 1 downto 0);
    theta_setpoint  : in  unsigned(data_length - 1 downto 0);
    alpha_setpoint  : in  unsigned(data_length - 1 downto 0);
    done            : out std_logic;
    control_input   : out unsigned(data_length - 1 downto 0)
  );

end paillier_inverted_pendulum;

architecture demo of paillier_inverted_pendulum is

  component plant_interface
    generic (
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
  end component;

  component controller_inverted_pendulum
    generic (
      constant key_length : natural;
      constant data_length : natural;
      constant N2 : unsigned(2047 downto 0);
      constant N2_dash : unsigned(15 downto 0);
      constant N_mont : unsigned(2047 downto 0);
      constant N_plus_1_mont : unsigned(2047 downto 0);
      constant k_p_theta : unsigned(2047 downto 0);
      constant k_d_theta : unsigned(2047 downto 0);
      constant k_alpha : unsigned(2047 downto 0);
      constant neg_k_d_theta : unsigned(2047 downto 0);
      constant neg_k_d_alpha : unsigned(2047 downto 0);
      constant R2_mod_N2 : unsigned(2047 downto 0);
      constant R_mod_N2 : unsigned(2047 downto 0)
    );
    port (
      clk            : in  std_logic;
      start          : in  std_logic;
      task           : in  controller_task;
      theta          : in  unsigned(key_length * 2 + 15 downto 0);
      alpha          : in  unsigned(key_length * 2 + 15 downto 0);
      done           : out std_logic;
      control_input  : out unsigned(key_length * 2 + 15 downto 0)
    );
  end component;

  signal plant_interface_task_signal : plant_interface_task := encrypt;
  signal controller_task_signal : controller_task := setpoint;
  signal theta_reg, alpha_reg, theta_setpoint_reg, alpha_setpoint_reg : unsigned(data_length - 1 downto 0) := (others => '0');
  signal plant_interface_in, plant_interface_out, controller_theta, controller_alpha, control_input_enc, control_input_enc_reg, theta_enc_reg : unsigned(key_length * 2 + 15 downto 0) := (others => '0');
  signal plant_interface_start, controller_start, plant_interface_done, controller_done, first_iteration, plant_interface_last_iteration, controller_last_iteration : std_logic := '0';
  signal plant_interface_counter : natural range 0 to 5 := 0;
  signal controller_counter : natural range 0 to 3 := 0;

begin

  -- Set output signals
  done <= plant_interface_done and controller_done and plant_interface_last_iteration and controller_last_iteration;
  control_input <= plant_interface_out(data_length - 1 downto 0);

  demo_enc_dec : plant_interface
  generic map(
    key_length => key_length,
    N2 => N2,
    N2_dash => N2_dash,
    N_mont => N_mont,
    N_plus_1_mont => N_plus_1_mont,
    N2_plus_2 => N2_plus_2,
    N2_plus_2_dash => N2_plus_2_dash,
    N => N,
    N_dash => N_dash,
    random_seed => random_seed,
    lambda => lambda,
    N_inv_R_mont => N_inv_R_mont,
    mu_mont => mu_mont,
    R2_mod_N2 => R2_mod_N2,
    R_mod_N2 => R_mod_N2
  )
  port map (
    clk => clk,
    start => plant_interface_start,
    task => plant_interface_task_signal,
    data_in => plant_interface_in,
    done => plant_interface_done,
    data_out => plant_interface_out
  );
  plant_interface_task_signal <= encrypt when plant_interface_counter = 0 or plant_interface_counter = 1 else
                                 rng when plant_interface_counter = 2 or plant_interface_counter = 3 else
                                 decrypt;
  plant_interface_in <= resize(theta_reg, key_length * 2 + 16) when plant_interface_counter = 0 else
                        resize(alpha_reg, key_length * 2 + 16) when plant_interface_counter = 1 else
                        to_unsigned(1234567890, key_length * 2 + 16) when plant_interface_counter = 2 or plant_interface_counter = 3 else
                        control_input_enc_reg;

  demo_con : controller_inverted_pendulum
  generic map(
    key_length => key_length,
    data_length => data_length,
    N2 => N2,
    N2_dash => N2_dash,
    N_mont => N_mont,
    N_plus_1_mont => N_plus_1_mont,
    k_p_theta => k_p_theta,
    k_d_theta => k_d_theta,
    k_alpha => k_alpha,
    neg_k_d_theta => neg_k_d_theta,
    neg_k_d_alpha => neg_k_d_alpha,
    R2_mod_N2 => R2_mod_N2,
    R_mod_N2 => R_mod_N2
  )
  port map (
    clk => clk,
    start => controller_start,
    task => controller_task_signal,
    theta => controller_theta,
    alpha => controller_alpha,
    done => controller_done,
    control_input => control_input_enc
  );
  controller_task_signal <= setpoint when controller_counter = 0 else
                            control when controller_counter = 1 else
                            update_state;
  controller_theta <= resize(theta_setpoint_reg, key_length * 2 + 16) when controller_counter = 0 else
                      theta_enc_reg;
  controller_alpha <= resize(alpha_setpoint_reg, key_length * 2 + 16) when controller_counter = 0 else
                      plant_interface_out;

  plant_interface_last_iteration <= '1' when plant_interface_counter = 5 else '0';
  controller_last_iteration <= '1' when controller_counter = 3 else '0';
  plant_interface_start <= '1' when first_iteration = '1' or (plant_interface_done = '1' and plant_interface_last_iteration = '0') else
                           '0';
  controller_start <= '1' when first_iteration = '1' or (controller_done = '1' and controller_last_iteration = '0' and (controller_counter /= 1 or (plant_interface_counter = 2 and plant_interface_done = '1'))) else
                      '0';

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        -- Update input registers and counter, start baseloop for the first time
        theta_reg <= theta;
        alpha_reg <= alpha;
        theta_setpoint_reg <= theta_setpoint;
        alpha_setpoint_reg <= alpha_setpoint;
        plant_interface_counter <= 0;
        controller_counter <= 0;
        first_iteration <= '1';
      else
        if (controller_start = '1') then
          -- Increment counter
          controller_counter <= controller_counter + 1;
        end if;
        if (plant_interface_start = '1') then
          -- Increment counter
          plant_interface_counter <= plant_interface_counter + 1;
        end if;
        if (first_iteration = '1') then
          first_iteration <= '0';
        end if;
        if (controller_counter = 2 and controller_done = '1') then
          control_input_enc_reg <= control_input_enc;
        end if;
        if (plant_interface_counter = 1 and plant_interface_done = '1') then
          theta_enc_reg <= plant_interface_out;
        end if;
      end if;
    end if;
  end process;

end demo;