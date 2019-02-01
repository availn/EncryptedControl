library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.plant_interface_types.all;

entity C5P is

  generic (
    constant cycles_per_sampling : natural := 30000;
    constant key_length : natural := 256;
    constant data_length : natural := 32;
    constant N2 : unsigned(2047 downto 0) := resize(x"1778EB55F880F45868FCBBAA0E3411D3B134284D427EE14309C24941EB42E9B7A63200697FA831F9079F50C23D151877A764ACF0BE62040A94CF09BDDF23469", 2048);
    constant N2_dash : unsigned(15 downto 0) := resize(x"6427", 16);
    constant N_mont : unsigned(2047 downto 0) := resize(x"138FD70691ED6093BA71A1D3DC302F7E24D692CDE4AEF2F0287E865E1FD0A1045DEB148374ED4722F556808B87B567C4D52A30E6A9B0240ECD87DF27F2F8BA5", 2048);
    constant N_plus_1_mont : unsigned(2047 downto 0) := resize(x"A61394247DD8E660BC2132DD5DCFE7A8A930EBBC26C7DF710A66C272632786A2835382CAE13CEDE09C25B4B4A83599F04E7D9D7C28A5416448920E3D253BDF", 2048);
    constant N2_plus_2 : unsigned(2047 downto 0) := resize(x"1778EB55F880F45868FCBBAA0E3411D3B134284D427EE14309C24941EB42E9B7A63200697FA831F9079F50C23D151877A764ACF0BE62040A94CF09BDDF2346B", 2048);
    constant N2_plus_2_dash : unsigned(15 downto 0) := resize(x"27BD", 16);
    constant N : unsigned(2047 downto 0) := resize(x"13611A1EC706880C740F5081ECE4FABD0866205F6DD4061577A9275E12695093", 2048);
    constant N_dash : unsigned(15 downto 0) := resize(x"B265", 16);
    constant random_seed : unsigned(2047 downto 0) := resize(x"B1FEEFAFADBE9EFDBACD510261CCF4F17A5088BA4D402DC93BBA837CB4826C27A109463FAEFEF20662D96DA751B5E811E51EED0665E4F8FFEA89C610BD5FA8", 2048);
    constant lambda : unsigned(2047 downto 0) := resize(x"33AD9AFCBD66C021357E2C0522629CA0B8D0DCD6C99331A360C85042AA8C348", 2048);
    constant N_inv_R_mont : unsigned(2047 downto 0) := resize(x"14FFB8D29D6FFE75E4B10794BF40B6FD27039C9B7CB1F727884A229F5130ACB082C505AF92D33B2163C8C7DD4BDBE1DBC2381AE8446D13B6C97B7B8A916F80D", 2048);
    constant mu_mont : unsigned(2047 downto 0) := resize(x"E228860E3E3B5BDC36E523B5A2B7FF2FCD227B92F62D4B7FDC1A8ED984BD474", 2048);
    constant k_p_theta : unsigned(2047 downto 0) := resize(x"FFFFFFDF", 2048);
    constant k_d_theta : unsigned(2047 downto 0) := resize(x"FFFFE00B", 2048);
    constant k_alpha : unsigned(2047 downto 0) := resize(x"FFFFD623", 2048);
    constant neg_k_d_theta : unsigned(2047 downto 0) := resize(x"1FF5", 2048);
    constant neg_k_d_alpha : unsigned(2047 downto 0) := resize(x"27F3", 2048);
    constant R2_mod_N2 : unsigned(2047 downto 0) := resize(x"BDD0D1FC84A56B42D19C5A9DB797FA71960982BAB9EE33BB2485A3493B365A75012A71B635151A77167FAD41A5A2689667AFBC6EA822F61FBEEA76D6AE4476", 2048);
    constant R_mod_N2 : unsigned(2047 downto 0) := resize(x"E4A4D91AE71222ABA4D2D0407E0E0D016F0A43B203C6C49F1EA2F0AF1A4C11D707C2412B8CEB9B41C0B2B81FFE30A51D72255E1D73C34120BD04B79BE7E4A3", 2048)
  );
  port (
    CLOCK_50_B3B : in std_logic;
    KEY : in std_logic_vector(3 downto 0);
    SW : in std_logic_vector(3 downto 0);
    LED : out std_logic_vector(3 downto 0);
    UART_TX : out std_logic;
    GPIO_0 : inout std_logic_vector(35 downto 0);
    HEX0 : out std_logic_vector(6 downto 0);
    HEX1 : out std_logic_vector(6 downto 0)
  );

end C5P;

architecture whole_system of C5P is

  component paillier_inverted_pendulum
    generic (
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
  end component;

  component uart
    generic (
      constant input_width : natural;
      constant cycles_per_bit : natural
    );
    port (
      clk        : in  std_logic;
      start      : in  std_logic;
      bus_in     : in  unsigned(47 downto 0);
      done       : out std_logic;
      serial_out : out std_logic
    );
  end component;

  component pll
    port (
      refclk   : in  std_logic;
      rst      : in  std_logic;
      outclk_0 : out std_logic
    );
  end component;

  component spi
    generic (
      constant input_width : natural;
      constant cycles_per_half_bit : natural
    );
    port (
      clk        : in  std_logic;
      start      : in  std_logic;
      miso       : in  std_logic;
      bus_in     : in  std_logic_vector(135 downto 0);
      done       : out std_logic;
      sclk       : out std_logic;
      mosi       : out std_logic;
      ss         : out std_logic;
      bus_out    : out std_logic_vector(135 downto 0)
    );
  end component;

  signal clk, slow_clk : std_logic;
  signal sampling_counter : natural range 0 to cycles_per_sampling - 1;
  signal speed_resized, speed_clamped : signed(14 downto 0);
  signal theta_raw, alpha_raw : unsigned(10 downto 0);
  signal theta, alpha, control_input, speed_rounded, theta_setpoint : unsigned(data_length - 1 downto 0);
  signal reset_encoders, enable_motor, uart_out, start_spi, start_uart, start_paillier, done, done_reg : std_logic;

begin

  clk <= CLOCK_50_B3B;
  UART_TX <= uart_out;

  GPIO_0(10) <= '1';
  GPIO_0(18) <= 'Z';
  GPIO_0(22) <= '0';

  LED(0) <= SW(0);
  LED(1) <= SW(1);
  LED(2) <= SW(2);
  LED(3) <= not KEY(3);

  reset_encoders <= not KEY(3);
  enable_motor <= '1' when SW(0) = '1' and alpha_raw > 896 and alpha_raw < 1152 else '0';

  speed_rounded <= control_input + resize(x"40", speed_rounded'length);
  speed_resized <= resize(signed(speed_rounded(31 downto 7)), speed_resized'length);
  speed_clamped <= to_signed(999, speed_clamped'length) when speed_resized > 999 else
                   to_signed(-999, speed_clamped'length) when speed_resized < -999 else
                   speed_resized;

  theta <= unsigned(resize(signed(theta_raw), theta'length));
  alpha <= resize(alpha_raw, alpha'length);

  theta_setpoint <= to_unsigned(0, theta_setpoint'length) when SW(1) = '1' else to_unsigned(256, theta_setpoint'length);

  start_paillier <= done and not done_reg;
  start_uart <= start_spi and SW(2);

  pll_slow : pll port map (
    refclk => clk,
    rst => '0',
    outclk_0 => slow_clk
  );

  DUT_paillier : paillier_inverted_pendulum
  generic map (
    key_length => key_length,
    data_length => data_length,
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
    k_p_theta => k_p_theta,
    k_d_theta => k_d_theta,
    k_alpha => k_alpha,
    neg_k_d_theta => neg_k_d_theta,
    neg_k_d_alpha => neg_k_d_alpha,
    R2_mod_N2 => R2_mod_N2,
    R_mod_N2 => R_mod_N2
  )
  port map (
    clk => slow_clk,
    start => start_paillier,
    theta => theta,
    alpha => alpha,
    theta_setpoint => theta_setpoint,
    alpha_setpoint => to_unsigned(1024, data_length),
    done => open,
    control_input => control_input
  );

  spi_inst : spi
  generic map (
    input_width => 136,
    cycles_per_half_bit => 8
  )
  port map (
    clk => slow_clk,
    start => start_spi,
    miso => GPIO_0(14),
    bus_in => x"0100" & b"0" & reset_encoders & reset_encoders & b"00011" & x"000000000000000000000000" & enable_motor & std_logic_vector(speed_clamped),
    done => done,
    sclk => GPIO_0(16),
    mosi => GPIO_0(12),
    ss => GPIO_0(20),
    signed(bus_out(106 downto 96)) => theta_raw,
    signed(bus_out(82 downto 72)) => alpha_raw
  );

  uart_test : uart
  generic map (
    input_width => 48,
    cycles_per_bit => 391
  )
  port map (
    clk => slow_clk,
    start => start_uart,
    bus_in(47 downto 32) => unsigned(resize(speed_clamped, 16)),
    bus_in(31 downto 16) => resize(alpha_raw, 16),
    bus_in(15 downto 0) => resize(theta_raw, 16),
    done => open,
    serial_out => uart_out
  );

  process (slow_clk)
  begin
    if(rising_edge(slow_clk)) then
      if (sampling_counter = cycles_per_sampling - 1) then
        sampling_counter <= 0;
        start_spi <= '1';
      else
        sampling_counter <= sampling_counter + 1;
        if (start_spi = '1') then
          start_spi <= '0';
        end if;
        done_reg <= done;
      end if;
    end if;
  end process;

end whole_system;