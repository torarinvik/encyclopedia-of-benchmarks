module binomial_coefficient_prime_power;

const long MAX_MODULUS = 1000000000;
const usz MAX_QUERIES = 32;
const usz MAX_N = 128;
const usz MAX_PARSEABLE = 68;

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor <= value / divisor; divisor++)
        if (value % divisor == 0) return false;
    return true;
}

fn long pow_mod(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long binomial_coefficient_prime_power(long* input, usz length, char* output, usz capacity)
        @export("binomial_coefficient_prime_power") {
    if (input == null || length < 3 || length > MAX_PARSEABLE) return -1;
    long p = input[0], e = input[1], q_arg = input[2];
    if (p < 2 || p > 31 || !is_prime(p) || e < 1 || e > 8 || q_arg < 0 || q_arg > MAX_QUERIES) return -1;
    long modulus = 1;
    for (long index = 0; index < e; index++) {
        modulus *= p;
        if (modulus > MAX_MODULUS) return -1;
    }
    usz q = (usz)q_arg;
    if (length != 3 + 2 * q) return -1;
    for (usz index = 0; index < q; index++) {
        long n = input[3 + 2 * index], k = input[4 + 2 * index];
        if (n < 0 || n > MAX_N || k < 0 || k > n) return -1;
    }
    if (q == 0) return 0;
    usz required = 4 * q;
    if (output == null || capacity < required) return -2;

    long[MAX_N + 1] unit_prefix = zeroed, p_free_factorial = zeroed;
    ushort[MAX_N + 1] valuation = zeroed;
    uint[MAX_QUERIES] residues = zeroed;
    unit_prefix[0] = 1;
    p_free_factorial[0] = 1;
    for (usz n = 1; n <= MAX_N; n++) {
        long factor = n % (usz)p == 0 ? 1 : (long)n;
        unit_prefix[n] = unit_prefix[n - 1] * factor % modulus;
        p_free_factorial[n] = unit_prefix[n] * p_free_factorial[n / (usz)p] % modulus;
        valuation[n] = (ushort)(n / (usz)p + valuation[n / (usz)p]);
    }
    long phi = modulus / p * (p - 1);
    for (usz index = 0; index < q; index++) {
        usz n = (usz)input[3 + 2 * index], k = (usz)input[4 + 2 * index];
        usz p_power = (usz)(valuation[n] - valuation[k] - valuation[n - k]);
        if (p_power < (usz)e) {
            long denominator = p_free_factorial[k] * p_free_factorial[n - k] % modulus;
            long inverse = pow_mod(denominator, phi - 1, modulus);
            long prime_factor = pow_mod(p, (long)p_power, modulus);
            residues[index] = (uint)(p_free_factorial[n] * inverse % modulus * prime_factor % modulus);
        }
    }
    for (usz index = 0; index < q; index++)
        for (usz byte = 0; byte < 4; byte++)
            output[4 * index + byte] = (char)(residues[index] >> (8 * byte));
    return (long)required;
}
