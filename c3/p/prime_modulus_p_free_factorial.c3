module prime_modulus_p_free_factorial;

const long MAX_PRIME = 1009;
const usz MAX_PARSEABLE_LENGTH = 3;

fn bool is_prime(long value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    long divisor = 3;
    while (divisor <= value / divisor) {
        if (value % divisor == 0) return false;
        divisor += 2;
    }
    return true;
}

fn long prime_modulus_p_free_factorial(long* input, usz length)
    @export("prime_modulus_p_free_factorial") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 2) return -1;
    long n = input[0];
    long prime = input[1];
    if (n < 0 || prime < 2 || prime > MAX_PRIME || !is_prime(prime)) return -1;

    long[MAX_PRIME] factorial;
    factorial[0] = 1;
    for (long i = 1; i < prime; ++i)
        factorial[i] = factorial[i - 1] * i % prime;

    long result = 1;
    long remaining = n;
    while (remaining > 0) {
        long quotient = remaining / prime;
        long residue = remaining % prime;
        result = result * factorial[residue] % prime;
        if ((quotient & 1) != 0) result = prime - result;
        remaining = quotient;
    }
    return result;
}
