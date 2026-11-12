module legendre_prime_count;

const long MAX_INPUT = 10000L;

fn long legendre_phi(long* primes, long value, long count) {
    if (value == 0) return 0;
    if (count == 0) return value;
    if (count == 1) return value - value / 2;
    long prime = primes[count - 1];
    if (value < prime) return 1;
    return legendre_phi(primes, value, count - 1) -
        legendre_phi(primes, value / prime, count - 1);
}

fn long legendre_prime_count(long value) @export("legendre_prime_count") {
    if (value < 0 || value > MAX_INPUT) return -1;
    if (value < 2) return 0;
    long root = 0;
    while ((root + 1) * (root + 1) <= value) root += 1;
    bool[101] composite = {};
    for (long candidate = 2; candidate * candidate <= root; candidate += 1) {
        if (composite[candidate]) continue;
        for (long multiple = candidate * candidate; multiple <= root; multiple += candidate)
            composite[multiple] = true;
    }
    long[25] primes;
    long count = 0;
    for (long candidate = 2; candidate <= root; candidate += 1)
        if (!composite[candidate]) primes[count++] = candidate;
    return legendre_phi(&primes[0], value, count) + count - 1;
}
