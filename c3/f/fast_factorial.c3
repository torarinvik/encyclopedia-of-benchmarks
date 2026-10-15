module fast_factorial;

const usz MAX_N = 20;
const usz MAX_BUCKETS = 8;

fn long exponent_in_factorial(long prime, long n) {
    long exponent = 0;
    long quotient = n / prime;
    while (quotient > 0) {
        exponent += quotient;
        quotient /= prime;
    }
    return exponent;
}

fn long power_by_squaring(long base, uint exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1u) != 0) result *= base;
        exponent >>= 1;
        if (exponent > 0) base *= base;
    }
    return result;
}

fn long fast_factorial(long n) @export("fast_factorial") {
    if (n < 0 || n > (long)MAX_N) return -1;
    if (n < 2) return 1;

    bool[MAX_N + 1] is_prime;
    for (usz index = 0; index <= MAX_N; index++) is_prime[index] = false;
    for (long candidate = 2; candidate <= n; candidate++) is_prime[(usz)candidate] = true;
    for (long prime = 2; prime * prime <= n; prime++) {
        if (!is_prime[(usz)prime]) continue;
        for (long multiple = prime * prime; multiple <= n; multiple += prime)
            is_prime[(usz)multiple] = false;
    }

    long exponent_of_two = exponent_in_factorial(2, n);
    long next_power_of_two = 1;
    uint power_log2 = 0;
    while (next_power_of_two < exponent_of_two) {
        next_power_of_two <<= 1;
        power_log2++;
    }
    usz bucket_count = (usz)(power_log2 + 1);
    long[MAX_BUCKETS] buckets;
    for (usz bit = 0; bit < MAX_BUCKETS; bit++) buckets[bit] = 1;

    for (long prime = 2; prime <= n; prime++) {
        if (!is_prime[(usz)prime]) continue;
        uint exponent_bits = (uint)exponent_in_factorial(prime, n);
        uint mask = 1;
        for (usz bit = 0; bit < bucket_count; bit++) {
            if ((exponent_bits & mask) != 0) buckets[bit] *= prime;
            mask <<= 1;
        }
    }

    long result = 1;
    uint power_exponent = 1;
    for (usz bit = 0; bit < bucket_count; bit++) {
        result *= power_by_squaring(buckets[bit], power_exponent);
        power_exponent <<= 1;
    }
    return result;
}
