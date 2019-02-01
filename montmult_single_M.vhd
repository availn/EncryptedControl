library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity montmult_single_M is

  generic (
    -- Should be multiple of 16
    constant M_length : natural;
    constant M : unsigned(2047 downto 0);
    constant M_dash : unsigned(15 downto 0)
  );

  port (
    clk          : in  std_logic;
    start        : in  std_logic;
    multiplier   : in  unsigned(M_length + 15 downto 0);
    multiplicand : in  unsigned(M_length + 15 downto 0);
    done         : out std_logic;
    product      : out unsigned(M_length + 15 downto 0)
  );

end montmult_single_M;

architecture cios of montmult_single_M is

  -- Declare I/O registers
  signal multiplier_reg, multiplicand_reg, T_reg : unsigned(M_length + 15 downto 0);
  signal Z, Z_reg, T : unsigned(M_length + 31 downto 0);
  signal U : unsigned(31 downto 0);
  signal counter : natural range 0 to natural(M_length / 16) + 3 := natural(M_length / 16) + 3;

begin

  -- Set output signals
  done <= '1' when counter = natural(M_length / 16) + 2 else '0';
  product <= T_reg;

  -- Set internal signals
  Z <= multiplier_reg(15 downto 0) * multiplicand_reg;
  U <= (T_reg(15 downto 0) + Z_reg(15 downto 0)) * M_dash;
  T <= T_reg + Z_reg + M(M_length - 1 downto 0) * U(15 downto 0);

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
      end if;
    end if;
  end process;

end cios;