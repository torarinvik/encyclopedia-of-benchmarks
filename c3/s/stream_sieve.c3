module stream_sieve;

const MAX_PRIMES = 100;

int[100] prime_cache = {2};
usz prime_count = 1;
int next_candidate = 3;

fn bool is_prime_candidate(int candidate) {
    for (usz index = 0; index < prime_count; index++) {
        int divisor = prime_cache[index];
        if (divisor > candidate / divisor) break;
        if (candidate % divisor == 0) return false;
    }
    return true;
}

fn void extend_prime_cache(usz requested_count) {
    while (prime_count < requested_count) {
        int candidate = next_candidate;
        next_candidate++;
        if (is_prime_candidate(candidate)) prime_cache[prime_count++] = candidate;
    }
}

fn long stream_sieve(long number_of_primes, char* output, usz output_capacity) @export("stream_sieve") {
    if (number_of_primes < -2147483648 || number_of_primes > MAX_PRIMES) return -1;
    if (number_of_primes <= 0) return 0;
    usz count = (usz)number_of_primes;
    usz required = count * 4;
    if (output == null || output_capacity < required) return -2;

    extend_prime_cache(count);
    for (usz index = 0; index < count; index++) {
        uint bits = (uint)prime_cache[index];
        for (usz byte = 0; byte < 4; byte++) {
            output[index * 4 + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)required;
}
