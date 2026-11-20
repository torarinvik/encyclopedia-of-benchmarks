module wieferich_prime_count_up_to_limit;

const int MAX_LIMIT = 5000;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long modular_power(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

fn long count_wieferich_primes(long limit) {
    uchar[MAX_LIMIT + 1] prime;
    for (usz n = 0; n <= (usz)limit; n++) prime[n] = 1;
    prime[0] = 0;
    prime[1] = 0;
    for (long divisor = 2; divisor <= limit / divisor; divisor++) {
        if (prime[(usz)divisor] == 0) continue;
        for (long multiple = divisor * divisor; multiple <= limit; multiple += divisor)
            prime[(usz)multiple] = 0;
    }
    long count = 0;
    for (long p = 3; p <= limit; p += 2) {
        if (prime[(usz)p] != 0 && modular_power(2, p - 1, p * p) == 1) count++;
    }
    return count;
}

fn long wieferich_prime_count_up_to_limit(long* input, usz length)
    @export("wieferich_prime_count_up_to_limit") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1 || input[0] < 2 || input[0] > MAX_LIMIT) return -1;
    return count_wieferich_primes(input[0]);
}
