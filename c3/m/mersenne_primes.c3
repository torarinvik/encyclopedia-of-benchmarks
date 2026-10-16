module mersenne_primes;

fn long mersenne_primes(long n) @export("mersenne_primes") {
    if (n < 2 || n > 31) return -1;
    if (n == 2) return 1;
    long modulus = (1L << n) - 1;
    long residue = 4;
    for (long round = 0; round < n - 2; round++) {
        residue = (residue * residue - 2) % modulus;
    }
    return residue == 0 ? 1 : 0;
}
