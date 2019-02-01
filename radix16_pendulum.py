# Returns the greatest common denominator of a and b
def gcd(a, b):
    if a < b:
        a , b = b, a
    while b:
        a , b = b, a % b
    return a

# Returns the least common multiple of a and b
def lcm(a, b):
    n = (a * b) // gcd(a, b)
    return n

# Returns R_inv such that (R * R_inv) mod N = 1
def ModInv(R, N):
    (t, newt) = (0, 1)
    (r, newr) = (N, R)

    while newr != 0:
        quotient = r // newr
        (t, newt) = (newt, t - quotient * newt)
        (r, newr) = (newr, r - quotient * newr)
    if r > 1:
        return -1
    if t < 0:
        t = t + N
    return t

key_length = 64
key_length = 256
data_length = 32
b = 16
n = key_length * 2 / b
R = 2 ** ((n + 1) * b)

# p and q are 32 bits
p = 2484208213
q = 3936009647
# p and q are 128 bits
p = 219364383201191163012722616532681091449
q = 39958668018998705262388252865894077291

# N_key is 64 bits
N_key = p * q
N2 = N_key ** 2
N2_plus_2 = N_key ** 2 + 2

N_key_dash = (2 ** b * ModInv(2 ** b, N_key) - 1) // N_key
N2_dash = (2 ** b * ModInv(2 ** b, N2) - 1) // N2
N2_plus_2_dash = (2 ** b * ModInv(2 ** b, N2_plus_2) - 1) // (N2_plus_2)

# Returns (X * Y * R_inv) mod N
def MontMult(X, Y, N, N_dash):
    T = 0
    for i in range(0, n + 1):
        T0 = T % (2 ** b)
        X0 = X % (2 ** b)
        Yi = (Y // (2 ** (b * i))) % (2 ** b)
        U = ((T0 + X0 * Yi) * N_dash) % (2 ** b)
        T = (T + X * Yi + N * U) // (2 ** b)
    return T

R_mod_N2 = R % N2
def ModExp(Base, Exponent):
    S = R_mod_N2
    # Right to left binary method
    while Exponent:
        if Exponent & 1:
            S = MontMult(S, Base, N2, N2_dash)
        Base = MontMult(Base, Base, N2, N2_dash)
        Exponent = Exponent >> 1
    return S

N_plus_1_mont = MontMult(N_key + 1, R ** 2 % N2, N2, N2_dash) % N2
N_mont = MontMult(N_key, R ** 2 % N2, N2, N2_dash) % N2
lambda_key = lcm(p - 1, q - 1)
N_inv_R_mont = MontMult(ModInv(N_key, N2_plus_2), R ** 3 % N2_plus_2, N2_plus_2, N2_plus_2_dash) % N2_plus_2
mu_mont = MontMult(ModInv(lambda_key, N_key), R ** 2 % N2, N_key, N_key_dash) % N_key

k_p_theta = 3#2 ** data_length - 2 * 2
k_d_theta = 5#2 ** data_length - 2 * 2
k_p_alpha = 30 * 2
k_d_alpha = int(2.5 * 2)

k_alpha = 7#k_p_alpha + k_d_alpha
neg_k_d_theta = 11#2 ** data_length - k_d_theta
neg_k_d_alpha = 13#2 ** data_length - k_d_alpha

# encryption
random = ModExp(1234567890, N_key)

input_theta = 20015
input_theta = 2 ** data_length - input_theta
ciphertext_theta = MontMult(N_mont, input_theta, N2, N2_dash)
ciphertext_theta = MontMult(ciphertext_theta + 1, R ** 2 % N2, N2, N2_dash)
ciphertext_theta = MontMult(ciphertext_theta, random, N2, N2_dash)

input_alpha = 20017
input_alpha = 2 ** data_length - input_alpha
ciphertext_alpha = MontMult(N_mont, input_alpha, N2, N2_dash)
ciphertext_alpha = MontMult(ciphertext_alpha + 1, R ** 2 % N2, N2, N2_dash)
ciphertext_alpha = MontMult(ciphertext_alpha, random, N2, N2_dash)

# control
setpoint_theta = 210008
setpoint_theta = MontMult(N_mont, setpoint_theta, N2, N2_dash)
setpoint_theta = MontMult(setpoint_theta + 1, R ** 2 % N2, N2, N2_dash)

ciphertext1 = MontMult(ciphertext_theta, setpoint_theta, N2, N2_dash)
ciphertext1 = ModExp(ciphertext1, k_p_theta)
ciphertext2 = ModExp(ciphertext_theta, k_d_theta)
ciphertext3 = ModExp(ciphertext_alpha, k_alpha)
ciphertext = MontMult(ciphertext1, ciphertext2, N2, N2_dash)
ciphertext = MontMult(ciphertext, ciphertext3, N2, N2_dash)

# decryption
exponential = ModExp(ciphertext, lambda_key)
u = MontMult(exponential, 1, N2, N2_dash)
L_u_mont = MontMult(u - 1, N_inv_R_mont, N2_plus_2, N2_plus_2_dash)
L_u = MontMult(L_u_mont, 1, N2_plus_2, N2_plus_2_dash)
output = MontMult(L_u, mu_mont, N_key, N_key_dash)
print((output % (2 ** data_length)))

print('')

print('constant key_length : natural := ' +  str(key_length) + ';')
print('constant data_length : natural := ' +  str(data_length) + ';')
print('constant N2 : unsigned(2047 downto 0) := resize(x"' + format(N2, 'X') + '", 2048);')
print('constant N2_dash : unsigned(15 downto 0) := resize(x"' + format(N2_dash, 'X') + '", 16);')
print('constant N_mont : unsigned(2047 downto 0) := resize(x"' + format(N_mont, 'X') + '", 2048);')
print('constant N_plus_1_mont : unsigned(2047 downto 0) := resize(x"' + format(N_plus_1_mont, 'X') + '", 2048);')
print('constant N2_plus_2 : unsigned(2047 downto 0) := resize(x"' + format(N2_plus_2, 'X') + '", 2048);')
print('constant N2_plus_2_dash : unsigned(15 downto 0) := resize(x"' + format(N2_plus_2_dash, 'X') + '", 16);')
print('constant N : unsigned(2047 downto 0) := resize(x"' + format(N_key, 'X') + '", 2048);')
print('constant N_dash : unsigned(15 downto 0) := resize(x"' + format(N_key_dash, 'X') + '", 16);')
print('constant random_seed : unsigned(2047 downto 0) := resize(x"' + format(random, 'X') + '", 2048);')
print('constant lambda : unsigned(2047 downto 0) := resize(x"' + format(lambda_key, 'X') + '", 2048);')
print('constant N_inv_R_mont : unsigned(2047 downto 0) := resize(x"' + format(N_inv_R_mont, 'X') + '", 2048);')
print('constant mu_mont : unsigned(2047 downto 0) := resize(x"' + format(mu_mont, 'X') + '", 2048);')
print('constant k_p_theta : unsigned(2047 downto 0) := resize(x"' + format(k_p_theta, 'X') + '", 2048);')
print('constant k_d_theta : unsigned(2047 downto 0) := resize(x"' + format(k_d_theta, 'X') + '", 2048);')
print('constant k_alpha : unsigned(2047 downto 0) := resize(x"' + format(k_alpha, 'X') + '", 2048);')
print('constant neg_k_d_theta : unsigned(2047 downto 0) := resize(x"' + format(neg_k_d_theta, 'X') + '", 2048);')
print('constant neg_k_d_alpha : unsigned(2047 downto 0) := resize(x"' + format(neg_k_d_alpha, 'X') + '", 2048);')
print('constant R2_mod_N2 : unsigned(2047 downto 0) := resize(x"' + format(R ** 2 % N2, 'X') + '", 2048);')
print('constant R_mod_N2 : unsigned(2047 downto 0) := resize(x"' + format(R_mod_N2, 'X') + '", 2048)')