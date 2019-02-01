library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is

  generic (
    -- Should be multiple of 8
    constant input_width : natural;
    constant cycles_per_bit : natural
  );
  port (
    clk        : in  std_logic;
    start      : in  std_logic;
    bus_in     : in  unsigned(input_width - 1 downto 0);
    done       : out std_logic;
    serial_out : out std_logic
  );

end uart;

architecture uart_arch of uart is

  -- Declare I/O registers
  signal bus_reg : unsigned(input_width - 1 downto 0) := (others => '0');
  signal byte_counter : natural range 0 to natural(input_width / 8) + 1 := natural(input_width / 8) + 1;
  signal bit_counter : natural range 0 to 9 := 9;
  signal clk_counter : natural range 0 to cycles_per_bit - 1 := 0;

begin

  -- Set output signals
  done <= '1' when byte_counter = natural(input_width / 8) else
          '0';
  serial_out <= '1' when bit_counter = 9 or byte_counter = natural(input_width / 8) else
                '0' when bit_counter = 0 else
                bus_reg(0);

  process (clk)
  begin
    if (rising_edge(clk)) then
      if (start = '1') then
        -- Update input registers, reset internal registers and counter
        bus_reg <= bus_in;
        byte_counter <= 0;
        bit_counter <= 0;
        clk_counter <= 0;
      elsif (byte_counter < natural(input_width / 8)) then
        -- Increment counters
        if (clk_counter < cycles_per_bit - 1) then
          clk_counter <= clk_counter + 1;
        else
          clk_counter <= 0;
          if (bit_counter > 0 and bit_counter < 9) then
            -- Shift bus register
            bus_reg(input_width - 2 downto 0) <= bus_reg(input_width - 1 downto 1);
          end if;
          if (bit_counter < 9) then
            bit_counter <= bit_counter + 1;
          else
            bit_counter <= 0;
            byte_counter <= byte_counter + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

end uart_arch;