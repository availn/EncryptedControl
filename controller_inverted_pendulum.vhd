package controller_types is
  type controller_task is (setpoint, control, update_state);
end controller_types;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.controller_types.all;
use work.modexp_single_M_types.all;

entity controller_inverted_pendulum is

  generic (
    -- Should be multiple of 16
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

end controller_inverted_pendulum;

architecture montcontroller of controller_inverted_pendulum is

  component modexp_single_M
    generic (
      constant N2_length : natural;
      constant data_length : natural;
      constant N2 : unsigned(2047 downto 0);
      constant N2_dash : unsigned(15 downto 0);
      constant R_mod_N2 : unsigned(2047 downto 0)
    );
    port (
      clk          : in  std_logic;
      start        : in  std_logic;
      task         : in  modexp_single_M_task;
      base_in      : in  unsigned(key_length * 2 + 15 downto 0);
      exponent     : in  unsigned(key_length * 2 + 15 downto 0);
      done         : out std_logic;
      power        : out unsigned(key_length * 2 + 15 downto 0)
    );
  end component;

  signal task_reg : controller_task := setpoint;
  signal exp_task : modexp_single_M_task := modexp_mult;
  signal theta_reg, alpha_reg, theta_setpoint_reg, alpha_setpoint_reg, exp_base, exp_exponent, enc_base, enc_exponent, con_base, con_exponent, state_base, state_exponent, exp_out : unsigned(key_length * 2 + 15 downto 0) := (others => '0');
  signal state : unsigned(key_length * 2 + 15 downto 0) := R_mod_N2(key_length * 2 + 15 downto 0);
  signal exp_start, exp_done, first_iteration, last_iteration : std_logic := '0';
  signal counter : natural range 0 to 10 := 0;

begin

  -- Set output signals
  done <= exp_done and last_iteration;
  control_input <= exp_out;

  -- Set internal signals
  exp : modexp_single_M
  generic map(
    N2_length => key_length * 2,
    data_length => data_length,
    N2 => N2,
    N2_dash => N2_dash,
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
  exp_task <= modexp_exp when ((counter = 0 or counter = 2 or counter = 4 or counter = 6 or counter = 8) and task_reg = control) or ((counter = 0 or counter = 1) and task_reg = update_state) else modexp_mult;
  -- Select data inputs to modexp based on the task
  exp_base <= con_base when task_reg = control else
              state_base when task_reg = update_state else
              enc_base;
  exp_exponent <= con_exponent when task_reg = control else
                  state_exponent when task_reg = update_state else
                  enc_exponent;

  enc_base <= theta_reg when counter = 0 else
              alpha_reg when counter = 2 else
              exp_out + 1;
  enc_exponent <= N_mont(key_length * 2 + 15 downto 0) when counter = 0 or counter = 2 else
                  R2_mod_N2(key_length * 2 + 15 downto 0);
  
  con_base <= theta_reg when counter = 0 else
              theta_reg when counter = 4 else
              alpha_reg when counter = 6 else
              exp_out;
  con_exponent <= (others => '1') when counter = 0 else
                  theta_setpoint_reg when counter = 1 else
                  k_p_theta(key_length * 2 + 15 downto 0) when counter = 2 else
                  state when counter = 3 else
                  k_d_theta(key_length * 2 + 15 downto 0) when counter = 4 else
                  state when counter = 5 else
                  (others => '1') when counter = 6 else
                  alpha_setpoint_reg when counter = 7 else
                  k_alpha(key_length * 2 + 15 downto 0) when counter = 8 else
                  state;

  state_base <= theta_reg when counter = 0 else
                alpha_reg when counter = 1 else
                exp_out;
  state_exponent <= neg_k_d_theta(key_length * 2 + 15 downto 0) when counter = 0 else
                    neg_k_d_alpha(key_length * 2 + 15 downto 0) when counter = 1 else
                    state;

  last_iteration <= '1' when (counter = 4 and task_reg = setpoint) or
                             (counter = 10 and task_reg = control) or
                             (counter = 3 and task_reg = update_state) else
                    '0';
  exp_start <= first_iteration or (exp_done and not last_iteration);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        -- Update input registers and counter, start baseloop for the first time
        if (task /= update_state) then
          theta_reg <= theta;
          alpha_reg <= alpha;
        end if;
        counter <= 0;
        first_iteration <= '1';
        task_reg <= task;
      else
        if (exp_start = '1') then
          -- Increment counter
          counter <= counter + 1;
          if (first_iteration = '1') then
            first_iteration <= '0';
          end if;
        end if;
        if (task_reg = setpoint and counter = 2 and exp_done = '1') then
          theta_setpoint_reg <= exp_out;
        end if;
        if (task_reg = setpoint and counter = 4 and exp_done = '1') then
          alpha_setpoint_reg <= exp_out;
        end if;
        if (((task_reg = control and (counter = 4 or counter = 6)) or (task_reg = update_state and (counter = 1 or counter = 3))) and exp_done = '1') then
          state <= exp_out;
        end if;
        if (task_reg = control and counter = 1 and exp_done = '1') then
          theta_reg <= exp_out;
        end if;
        if (task_reg = control and counter = 8 and exp_done = '1') then
          alpha_reg <= exp_out;
        end if;
      end if;
    end if;
  end process;

end montcontroller;