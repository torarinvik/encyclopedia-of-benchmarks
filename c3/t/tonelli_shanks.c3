module tonelli_shanks;

fn long mod_pow(long base, long exponent, long modulus)
{
    long result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long legendre_symbol(long residue, long prime)
{
    long symbol = mod_pow(residue % prime, (prime - 1) / 2, prime);
    return symbol == prime - 1 ? -1 : symbol;
}

fn long tonelli_shanks(long* packed, usz length) @export("tonelli_shanks")
{
    if (length != 2) return -1;
    long residue = packed[0];
    long prime = packed[1];
    if (prime <= 2 || (prime & 1) == 0 || prime > 1000003 || residue < 0 || residue >= prime) return -1;
    if (residue == 0) return 0;
    if (legendre_symbol(residue, prime) != 1) return -1;
    if (prime % 4 == 3) {
        long root = mod_pow(residue, (prime + 1) / 4, prime);
        return root < prime - root ? root : prime - root;
    }
    long q = prime - 1;
    long s = 0;
    while ((q & 1) == 0) { q /= 2; s++; }
    long non_residue = 2;
    while (legendre_symbol(non_residue, prime) != -1) non_residue++;
    long c = mod_pow(non_residue, q, prime);
    long r = mod_pow(residue, (q + 1) / 2, prime);
    long t = mod_pow(residue, q, prime);
    long remaining_s = s;
    while (t != 1) {
        long test_power = t;
        long least_i = 0;
        for (long candidate_i = 1; candidate_i < remaining_s; candidate_i++) {
            test_power = mod_pow(test_power, 2, prime);
            if (test_power == 1) { least_i = candidate_i; break; }
        }
        if (least_i == 0) return -1;
        long b = mod_pow(c, 1L << (remaining_s - least_i - 1), prime);
        r = (r * b) % prime;
        c = (b * b) % prime;
        t = (t * c) % prime;
        remaining_s = least_i;
    }
    return r < prime - r ? r : prime - r;
}
