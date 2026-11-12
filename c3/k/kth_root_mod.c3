module kth_root_mod;

const long MAX_T = 8;
const long MAX_K = 1000000000;
const long MAX_P = 1000;

fn long modular_power(long base, long exponent, long modulus) {
    long result = 1 % modulus;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

fn bool is_prime(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor * divisor <= value; divisor += 1)
        if (value % divisor == 0) return false;
    return true;
}

fn usz factor_distinct(long value, long* factors) {
    usz count = 0;
    for (long divisor = 2; divisor * divisor <= value; divisor += 1) {
        if (value % divisor != 0) continue;
        factors[count++] = divisor;
        do value /= divisor; while (value % divisor == 0);
    }
    if (value > 1) factors[count++] = value;
    return count;
}

fn long primitive_root(long prime) {
    if (prime == 2) return 1;
    long order = prime - 1;
    long factors[16];
    usz count = factor_distinct(order, factors);
    for (long candidate = 2; candidate < prime; candidate += 1) {
        usz i = 0;
        while (i < count && modular_power(candidate, order / factors[i], prime) != 1) i += 1;
        if (i == count) return candidate;
    }
    return -1;
}

fn long gcd_i64(long a, long b) {
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a;
}

fn long modular_inverse(long value, long modulus) {
    long old_t = 0, new_t = 1, old_r = modulus, new_r = value % modulus;
    while (new_r != 0) {
        long quotient = old_r / new_r;
        long next_t = old_t - quotient * new_t;
        long next_r = old_r - quotient * new_r;
        old_t = new_t; new_t = next_t; old_r = new_r; new_r = next_r;
    }
    if (old_t < 0) old_t += modulus;
    return old_t;
}

fn long kth_root(long exponent, long residue, long prime) {
    if (exponent == 0) return residue == 1 ? 0 : -1;
    if (residue == 0) return 0;
    long order = prime - 1, generator = primitive_root(prime);
    long power = 1, discrete_log = -1;
    for (long candidate = 0; candidate < order; candidate += 1) {
        if (power == residue) { discrete_log = candidate; break; }
        power = power * generator % prime;
    }
    if (discrete_log < 0) return -1;
    long common = gcd_i64(exponent, order);
    if (discrete_log % common != 0) return -1;
    long reduced_order = order / common, root_exponent = 0;
    if (reduced_order > 1) {
        long inverse = modular_inverse((exponent / common) % reduced_order, reduced_order);
        root_exponent = (discrete_log / common) * inverse % reduced_order;
    }
    long root = modular_power(generator, root_exponent, prime);
    return modular_power(root, exponent, prime) == residue ? root : -1;
}

fn long kth_root_mod(long* input, usz length, char* output, usz capacity) @export("kth_root_mod") {
    if (input == null || length < 4 || length > 1 + 3 * (usz)MAX_T) return -1;
    long t_value = input[0];
    if (t_value < 1 || t_value > MAX_T) return -1;
    usz t = (usz)t_value;
    if (length != 1 + 3 * t) return -1;

    long triples[3 * MAX_T];
    for (usz i = 0; i < 3 * t; i += 3) {
        long exponent = input[i + 1], residue = input[i + 2], prime = input[i + 3];
        if (exponent < 0 || exponent > MAX_K || prime < 2 || prime > MAX_P ||
            residue < 0 || residue >= prime || !is_prime(prime)) return -1;
        triples[i] = exponent; triples[i + 1] = residue; triples[i + 2] = prime;
    }
    usz required = 8 * t;
    if (output == null || capacity < required) return -2;
    for (usz test = 0; test < t; test += 1) {
        ulong bits = (ulong)kth_root(triples[3 * test], triples[3 * test + 1], triples[3 * test + 2]);
        for (usz byte = 0; byte < 8; byte += 1)
            output[8 * test + byte] = (char)(bits >> (8 * byte));
    }
    return (long)required;
}
