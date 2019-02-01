package modexp_single_M_types is
  type modexp_single_M_task is (modexp_exp, modexp_mult);
end modexp_single_M_types;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.modexp_single_M_types.all;

entity modexp_single_M is
  
  generic (
    -- Should be multiple of 16
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
    base_in      : in  unsigned(N2_length + 15 downto 0);
    exponent     : in  unsigned(N2_length + 15 downto 0);
    done         : out std_logic;
    power        : out unsigned(N2_length + 15 downto 0)
  );

end modexp_single_M;

architecture righttoleft of modexp_single_M is

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
  signal task_reg : modexp_single_M_task := modexp_mult;
  signal base_reg, exponent_reg, power_reg, baseloop_in, baseloop_out, poweracc_in, poweracc_out : unsigned(N2_length + 15 downto 0) := (others => '0');
  signal counter : natural range 0 to natural(data_length) := 0;
  signal mult_first_start, last_iteration, mult_start, mult_done, old : std_logic := '0';

begin

  -- Set output signals
  done <= mult_done and last_iteration;
  power <= poweracc_out when old = '1' or task_reg = modexp_mult else power_reg;

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

  poweracc : montmult_single_M
  generic map(
    M_length => N2_length,
    M => N2,
    M_dash => N2_dash
  )
  port map (
    clk => clk,
    start => mult_start,
    multiplier => baseloop_in,
    multiplicand => poweracc_in,
    done => open,
    product => poweracc_out
  );
  poweracc_in <= exponent_reg when task_reg = modexp_mult else
                 power_reg when old = '0' else
                 poweracc_out;

  last_iteration <= '1' when counter = natural(data_length) or (counter = 1 and task_reg = modexp_mult) else '0';
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
      elsif (mult_start = '1') then
        -- Shift exponent register
        exponent_reg(data_length - 2 downto 0) <= exponent_reg(data_length - 1 downto 1);
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