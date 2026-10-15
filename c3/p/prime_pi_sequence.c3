module prime_pi_sequence;

const long MAX_INDEX = 999L;

fn long prime_pi_sequence(long index) @export("prime_pi_sequence") {
    if (index < 0 || index > MAX_INDEX) return -1;
    long target = index + 1;
    long[168] primes;
    long prime_count = 0;
    if (target >= 2) primes[prime_count++] = 2;
    for (long candidate = 3; candidate <= target; candidate += 2) {
        bool is_prime = true;
        for (long i = 0; i < prime_count; i += 1) {
            if (candidate % primes[i] == 0) {
                is_prime = false;
                break;
            }
        }
        if (is_prime) primes[prime_count++] = candidate;
    }
    return prime_count;
}
