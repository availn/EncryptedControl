library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity paillier_inverted_pendulum_tben is

  generic (
    constant key_length : natural := 512;
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
    constant k_p_theta : unsigned(2047 downto 0) := resize(x"3", 2048);
    constant k_d_theta : unsigned(2047 downto 0) := resize(x"5", 2048);
    constant k_alpha : unsigned(2047 downto 0) := resize(x"7", 2048);
    constant neg_k_d_theta : unsigned(2047 downto 0) := resize(x"B", 2048);
    constant neg_k_d_alpha : unsigned(2047 downto 0) := resize(x"D", 2048);
    constant R2_mod_N2 : unsigned(2047 downto 0) := resize(x"BDD0D1FC84A56B42D19C5A9DB797FA71960982BAB9EE33BB2485A3493B365A75012A71B635151A77167FAD41A5A2689667AFBC6EA822F61FBEEA76D6AE4476", 2048);
    constant R_mod_N2 : unsigned(2047 downto 0) := resize(x"E4A4D91AE71222ABA4D2D0407E0E0D016F0A43B203C6C49F1EA2F0AF1A4C11D707C2412B8CEB9B41C0B2B81FFE30A51D72255E1D73C34120BD04B79BE7E4A3", 2048)
  );

end paillier_inverted_pendulum_tben;

architecture tben of paillier_inverted_pendulum_tben is

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

  signal clk, start, done : std_logic := '0';
  signal theta, alpha, theta_setpoint, alpha_setpoint, control_input : unsigned(data_length - 1 downto 0) := (others => '0');

begin

  -- instantiate the devices under test
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
    clk => clk,
    start => start,
    theta => theta,
    alpha => alpha,
    theta_setpoint => theta_setpoint,
    alpha_setpoint => alpha_setpoint,
    done => done,
    control_input => control_input
  );

  -- specify the stimulus (start and clk)
  start <= '1' after 5 ns, '0' after 15 ns, '1' after 5000005 ns, '0' after 5000015 ns;
  theta <= to_unsigned(20015, data_length) after 5 ns, to_unsigned(20004, data_length) after 900005 ns;
  alpha <= to_unsigned(20017, data_length) after 5 ns, to_unsigned(20005, data_length) after 900005 ns;
  theta_setpoint <= to_unsigned(210008, data_length) after 5 ns, to_unsigned(210001, data_length) after 900005 ns;
  alpha_setpoint <= to_unsigned(0, data_length) after 5 ns, to_unsigned(2, data_length) after 900005 ns;
  process
  begin
    wait for 10 ns;
    clk <= not clk;
  end process;

end tben;