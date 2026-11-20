module powerful_number_summatory_sieve;

const usz MAX_SIEVE_LIMIT = 1000;

fn void enumerate_powerful(long n, long* primes, usz prime_count, usz start,
                           long current, long current_h, long* total) {
    long remaining = n / current;
    for (usz index = start; index < prime_count; index++) {
        long prime = primes[index];
        if (prime > remaining / prime) break;

        long prime_power = prime * prime;
        long h_power = prime - 1;
        while (prime_power <= remaining) {
            long powerful = current * prime_power;
            long h_value = current_h * h_power;
            *total += h_value * (n / powerful);
            enumerate_powerful(n, primes, prime_count, index + 1,
                               powerful, h_value, total);

            if (prime_power > remaining / prime) break;
            prime_power *= prime;
            h_power *= prime;
        }
    }
}

fn long powerful_number_summatory_sieve(long* input, usz length) @export("powerful_number_summatory_sieve") {
    if (input == null || length != 1) return -1;
    long n = input[0];
    if (n < 1 || n > 1000000) return -1;

    usz prime_limit = 0;
    while ((long)(prime_limit + 1) * (long)(prime_limit + 1) <= n)
        prime_limit++;

    bool[MAX_SIEVE_LIMIT + 1] is_prime = {};
    for (usz value = 0; value <= prime_limit; value++) is_prime[value] = true;
    is_prime[0] = false;
    if (prime_limit >= 1) is_prime[1] = false;
    for (usz prime = 2; prime * prime <= prime_limit; prime++) {
        if (!is_prime[prime]) continue;
        for (usz composite = prime * prime; composite <= prime_limit; composite += prime)
            is_prime[composite] = false;
    }

    long[MAX_SIEVE_LIMIT + 1] primes = {};
    usz prime_count = 0;
    for (usz value = 2; value <= prime_limit; value++) {
        if (is_prime[value]) primes[prime_count++] = (long)value;
    }
    long total = n;
    enumerate_powerful(n, &primes[0], prime_count, 0, 1, 1, &total);
    return total;
}
