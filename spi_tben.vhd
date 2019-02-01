library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_tben is
end spi_tben;

architecture tben of spi_tben is

  component spi
    generic (
    -- Should be multiple of 8
    constant input_width : natural;
    constant cycles_per_bit : natural
    );
    port (
      clk        : in  std_logic;
      start      : in  std_logic;
      miso       : in  std_logic;
      bus_in     : in  unsigned(input_width - 1 downto 0);
      done       : out std_logic;
      sclk       : out std_logic;
      mosi       : out std_logic;
      ss         : out std_logic;
      bus_out    : out unsigned(input_width - 1 downto 0)
    );
  end component;

  signal clk  : std_logic := '0';
  signal start : std_logic := '0';
  signal miso  : std_logic := '0';
  signal bus_in : unsigned(7 downto 0) := to_unsigned(65, 8);
  signal done : std_logic := '0';
  signal sclk  : std_logic := '0';
  signal mosi  : std_logic := '0';
  signal ss  : std_logic := '0';
  signal bus_out : unsigned(7 downto 0) := to_unsigned(0, 8);

begin

  -- instantiate the device under test
  DUT : spi 
  generic map (
    input_width => 8,
    cycles_per_bit => 10
  )
  port map (
    clk => clk,
    start => start,
    miso => miso,
    bus_in => bus_in,
    done => done,
    sclk => sclk,
    mosi => mosi,
    ss => ss,
    bus_out => bus_out
  );

  -- specify the stimulus (start and clk)
  start <= '1' after 5 ns, '0' after 15 ns;
  process
  begin
    wait for 10 ns;
    clk <= not clk;
  end process;

end tben;