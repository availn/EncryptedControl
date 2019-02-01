package modexp_triple_M_types is
  type modexp_triple_M_task is (modexp_exp_N2, modexp_mult_N2, modexp_mult_N2_plus_2, modexp_mult_N);
end modexp_triple_M_types;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.modexp_triple_M_types.all;
use work.montmult_types.all;

entity modexp_triple_M is
  
  generic (
    -- Should be multiple of 16
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
    base_in      : in  unsigned(N2_length + 15 downto 0);
    exponent     : in  unsigned(N2_length + 15 downto 0);
    done         : out std_logic;
    power        : out unsigned(N2_length + 15 downto 0)
  );

end modexp_triple_M;

architecture righttoleft of modexp_triple_M is

  component montmult_triple_M
    generic (
      constant M_length : natural;
      constant N2 : unsigned(2047 downto 0);
      constant N2_dash : unsigned(15 downto 0);
      constant N2_plus_2 : unsigned(2047 downto 0);
      constant N2_plus_2_dash : unsigned(15 downto 0);
      constant N : unsigned(2047 downto 0);
      constant N_dash : unsigned(15 downto 0)
    );
    port (
      clk          : in  std_logic;
      start        : in  std_logic;
      multiplier   : in  unsigned(N2_length + 15 downto 0);
      multiplicand : in  unsigned(N2_length + 15 downto 0);
      M_select     : in  montmult_M;
      done         : out std_logic;
      product      : out unsigned(N2_length + 15 downto 0)
    );
  end component;

  component montmult_single_M
    generic (
      constant M_length : natural;
      constant M : unsigned(2047 downto 0);
      constant M_dash : unsigned(15 downto 0)
    );
    port (
      clk          : in  std_logic;
      start        : in  std_logic;
      multiplier   : in  unsigned(N2_length + 15 downto 0);
      multiplicand : in  unsigned(N2_length + 15 downto 0);
      done         : out std_logic;
      product      : out unsigned(N2_length + 15 downto 0)
    );
  end component;

  -- Declare I/O registers
  signal task_reg : modexp_triple_M_task := modexp_exp_N2;
  signal M_select_reg : montmult_m := montmult_N2;
  signal base_reg, exponent_reg, power_reg, baseloop_in, baseloop_out, poweracc_in, poweracc_out : unsigned(N2_length + 15 downto 0) := (others => '0');
  signal counter : natural range 0 to natural(N2_length) := 0;
  signal mult_first_start, last_iteration, mult_start, mult_done, old : std_logic := '0';

begin

  -- Set output signals
  done <= mult_done and last_iteration;
  power <= poweracc_out when old = '1' or task_reg /= modexp_exp_N2 else power_reg;

  -- Set internal signals
  baseloop : montmult_single_M
  generic map(
    M_length => N2_length,
    M => N2,
    M_dash => N2_dash
  )
  port map (
    clk => clk,
    start => mult_start,
    multiplier => baseloop_in,
    multiplicand => baseloop_in,
    done => mult_done,
    product => baseloop_out
  );
  baseloop_in <= base_reg when mult_first_start = '1' else baseloop_out;

  poweracc : montmult_triple_M
  generic map(
    M_length => N2_length,
    N2 => N2,
    N2_dash => N2_dash,
    N2_plus_2 => N2_plus_2,
    N2_plus_2_dash => N2_plus_2_dash,
    N => N,
    N_dash => N_dash
  )
  port map (
    clk => clk,
    start => mult_start,
    multiplier => baseloop_in,
    multiplicand => poweracc_in,
    M_select => M_select_reg,
    done => open,
    product => poweracc_out
  );
  poweracc_in <= exponent_reg when task_reg /= modexp_exp_N2 else
                 power_reg when old = '0' else
                 poweracc_out;

  last_iteration <= '1' when counter = natural(N2_length) / 2 or (counter = 1 and task_reg /= modexp_exp_N2) else '0';
  mult_start <= mult_first_start or (mult_done and not last_iteration);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        -- Update input registers, reset internal registers and counter, start baseloop for the first time
        task_reg <= task;
        base_reg <= base_in;
        exponent_reg <= exponent;
        power_reg <= R_mod_N2(N2_length + 15 downto 0);
        counter <= 0;
        mult_first_start <= '1';
        old <= '0';
        case task is
          when modexp_exp_N2 =>
            M_select_reg <= montmult_N2;
          when modexp_mult_N2 =>
            M_select_reg <= montmult_N2;
          when modexp_mult_N2_plus_2 =>
            M_select_reg <= montmult_N2_plus_2;
          when modexp_mult_N =>
            M_select_reg <= montmult_N;
        end case;
      elsif (mult_start = '1') then
        -- Shift exponent register
        exponent_reg(N2_length + 14 downto 0) <= exponent_reg(N2_length + 15 downto 1);
        old <= exponent_reg(0);
        -- Update power_reg if multiplication just completed was necessary
        if (old = '1') then
          power_reg <= poweracc_out;
        end if;
        -- Increment counter
        counter <= counter + 1;
        if (mult_first_start = '1') then
          mult_first_start <= '0';
        end if;
      end if;
    end if;
  end process;

end righttoleft;