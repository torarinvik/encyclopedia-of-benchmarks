module ncr_modulo_p;

const long INVALID_RESULT = -9223372036854775807L - 1L;

fn long inverse(long a, long m) {
    long old_r = a, r = m;
    long old_s = 1, s = 0;
    while (r != 0) {
        long quotient = old_r / r;
        long next_r = old_r - quotient * r;
        long next_s = old_s - quotient * s;
        old_r = r; r = next_r;
        old_s = s; s = next_s;
    }
    return old_r == 1 ? (old_s + m) % m : -1;
}

fn long ncr_modulo_p(long* values, usz length) @export("ncr_modulo_p") {
    if (values == null || length != 4) return INVALID_RESULT;
    long size = values[0], p = values[1], n = values[2], r = values[3];
    if (size < 0 || size > 64 || p < 2 || p > 1009 || n < 0 || n > size ||
        r < 0 || r > 64) return INVALID_RESULT;

    long[65] fac;
    fac[0] = 1;
    for (long i = 1; i <= size; i++) fac[i] = (fac[i - 1] * i) % p;
    if (r > n) return 0;
    if (r == 1) return n % p;
    if (r == 0 || r == n) return 1;
    long denominator = (fac[r] * fac[n - r]) % p;
    long denominator_inv = inverse(denominator, p);
    if (denominator_inv < 0) return -1;
    return (fac[n] * denominator_inv) % p;
}
