module modular_inverse_fermat_little_theorem;

fn long binary_exponentiation(long base, long exponent, long modulus) {
    base = base % modulus;
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

fn bool is_prime(long value) {
    if (value <= 1) return false;
    for (long divisor = 2; divisor * divisor <= value; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long modular_inverse_fermat_little_theorem(long a, long m)
    @export("modular_inverse_fermat_little_theorem") {
    if (a < -1000000 || a > 1000000 || m < 2 || m > 1000000 ||
        a == 0 || a <= -m || a >= m || !is_prime(m)) return -1;
    while (a < 0) a += m;
    return binary_exponentiation(a, m - 2, m);
}
