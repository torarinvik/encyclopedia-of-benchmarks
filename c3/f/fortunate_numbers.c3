module fortunate_numbers;

const long MAX_N = 10;
const long SEARCH_MAX = 64;

fn bool is_prime_trial(long value) {
    if (value < 2) return false;
    for (long divisor = 2; divisor <= value / divisor; divisor++) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long fortunate_numbers(long* input, usz length) @export("fortunate_numbers") {
    if (input == null || length != 1) return -1;
    long n = input[0];
    if (n < 1 || n > MAX_N) return -1;
    long primorial = 1;
    long primes_found = 0;
    for (long candidate = 2; primes_found < n; candidate++) {
        if (is_prime_trial(candidate)) {
            primorial *= candidate;
            primes_found++;
        }
    }
    for (long offset = 2; offset <= SEARCH_MAX; offset++) {
        if (is_prime_trial(primorial + offset)) return offset;
    }
    return -2;
}
