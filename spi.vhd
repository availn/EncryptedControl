library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi is

  generic (
    -- Should be multiple of 8
    constant input_width : natural;
    constant cycles_per_half_bit : natural
  );
  port (
    clk        : in  std_logic;
    start      : in  std_logic;
    miso       : in  std_logic;
    bus_in     : in  std_logic_vector(input_width - 1 downto 0);
    done       : out std_logic;
    sclk       : out std_logic;
    mosi       : out std_logic;
    ss         : out std_logic;
    bus_out    : out std_logic_vector(input_width - 1 downto 0)
  );

end spi;

architecture spi_arch of spi is

  -- Declare I/O registers
  signal sclk_reg : std_logic := '1';
  signal bus_in_reg, bus_out_reg : std_logic_vector(input_width - 1 downto 0) := (others => '0');
  signal bit_counter : natural range 0 to input_width := input_width;
  signal clk_counter : natural range 0 to cycles_per_half_bit - 1 := 0;

begin

  -- Set output signals
  done <= '0' when bit_counter < input_width else '1';
  sclk <= sclk_reg;
  mosi <= bus_in_reg(input_width - 1);
  ss <= '0' when bit_counter < input_width else '1';
  bus_out <= bus_out_reg;

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        -- Update input registers, reset internal registers and counter
        bus_in_reg <= bus_in;
        bit_counter <= 0;
        clk_counter <= 0;
      elsif (bit_counter < input_width) then
        -- Increment counters
        if (clk_counter < cycles_per_half_bit - 1) then
          clk_counter <= clk_counter + 1;
        else
          if (sclk_reg = '0') then
            -- Shift bus_in register up
            bus_in_reg(input_width - 1 downto 1) <= bus_in_reg(input_width - 2 downto 0);
            bit_counter <= bit_counter + 1;
          else
            -- Shift bus_out register up
            bus_out_reg(input_width - 1 downto 1) <= bus_out_reg(input_width - 2 downto 0);
            bus_out_reg(0) <= miso;
          end if;
          clk_counter <= 0;
          sclk_reg <= not sclk_reg;
        end if;
      end if;
    end if;
  end process;

end spi_arch;