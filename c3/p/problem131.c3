module problem131;

const long MAX_PRIME = 1000000;

fn bool problem131_is_prime(long number) {
    if (number < 2) return false;
    for (long divisor = 2; divisor <= number / divisor; divisor++) {
        if (number % divisor == 0) return false;
    }
    return true;
}

fn long problem131(long max_prime) @export("problem131") {
    if (max_prime < 0 || max_prime > MAX_PRIME) return -1;
    long primes_count = 0;
    long cube_index = 1;
    long prime_candidate = 7;
    while (prime_candidate < max_prime) {
        if (problem131_is_prime(prime_candidate)) primes_count++;
        cube_index++;
        prime_candidate += 6 * cube_index;
    }
    return primes_count;
}
