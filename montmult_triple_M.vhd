package montmult_types is
  type montmult_M is (montmult_N2, montmult_N2_plus_2, montmult_N);
end montmult_types;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.montmult_types.all;

entity montmult_triple_M is

  generic (
    -- Should be multiple of 16
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
    multiplier   : in  unsigned(M_length + 15 downto 0);
    multiplicand : in  unsigned(M_length + 15 downto 0);
    M_select     : in  montmult_M;
    done         : out std_logic;
    product      : out unsigned(M_length + 15 downto 0)
  );

end montmult_triple_M;

architecture cios of montmult_triple_M is

  signal Z, Z_reg, T : unsigned(M_length + 31 downto 0) := (others => '0');
  signal multiplier_reg, multiplicand_reg, T_reg : unsigned(M_length + 15 downto 0) := (others => '0');
  signal M_reg : unsigned(M_length - 1 downto 0) := (others => '0');
  signal M_dash_reg : unsigned(15 downto 0) := (others => '0');
  signal U : unsigned(31 downto 0) := (others => '0');
  signal counter : natural range 0 to natural(M_length / 16) + 3 := natural(M_length / 16) + 3;

begin

  -- Set output signals
  done <= '1' when counter = natural(M_length / 16) + 2 else '0';
  product <= T_reg;

  -- Set internal signals
  Z <= multiplier_reg(15 downto 0) * multiplicand_reg;
  U <= (T_reg(15 downto 0) + Z_reg(15 downto 0)) * M_dash_reg;
  T <= T_reg + Z_reg + M_reg * U(15 downto 0);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1' or counter < natural(M_length / 16) + 2) then
        if (start = '1') then
          -- Clear T register and counter
          T_reg <= (others => '0');
          counter <= 0;
        else
          -- Shift T into register, increment counter
          T_reg <= T(M_length + 31 downto 16);
          counter <= counter + 1;
        end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        -- Update multiplier register, clear Z register
        multiplier_reg <= multiplier;
        Z_reg <= (others => '0');
      else
        -- Shift multiplicand register, update Z register
        multiplier_reg(M_length - 1 downto 0) <= multiplier_reg(M_length + 15 downto 16);
        Z_reg <= Z;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        multiplicand_reg <= multiplicand;
        case M_select is
          when montmult_N2 =>
            M_reg <= N2(M_length - 1 downto 0);
            M_dash_reg <= N2_dash;
          when montmult_N2_plus_2 =>
            M_reg <= N2_plus_2(M_length - 1 downto 0);
            M_dash_reg <= N2_plus_2_dash;
          when montmult_N =>
            M_reg <= N(M_length - 1 downto 0);
            M_dash_reg <= N_dash;
        end case;
      end if;
    end if;
  end process;

end cios;