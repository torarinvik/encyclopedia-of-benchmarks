module binomial_coefficient_lucas;

const long BCL_MAX_PRIME = 1009;

fn bool bcl_is_prime(long value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (long divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

fn long bcl_modular_power(long base, long exponent, long modulus) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent = exponent >> 1;
    }
    return result;
}

fn long binomial_coefficient_lucas(long* input, usz length)
    @export("binomial_coefficient_lucas") {
    if (input == null || length != 3) return -1;

    long n = input[0];
    long k = input[1];
    long prime = input[2];
    if (n < 0 || k < 0 || k > n || prime < 2
        || prime > BCL_MAX_PRIME || !bcl_is_prime(prime)) {
        return -1;
    }

    long[BCL_MAX_PRIME] factorial;
    long[BCL_MAX_PRIME] inverse_factorial;
    factorial[0] = 1;
    for (long i = 1; i < prime; i += 1) {
        factorial[i] = factorial[i - 1] * i % prime;
    }

    inverse_factorial[prime - 1] = bcl_modular_power(
        factorial[prime - 1], prime - 2, prime);
    for (long i = prime - 1; i > 0; i -= 1) {
        inverse_factorial[i - 1] = inverse_factorial[i] * i % prime;
    }

    long result = 1;
    while (n > 0 || k > 0) {
        long n_digit = n % prime;
        long k_digit = k % prime;
        if (k_digit > n_digit) return 0;

        long digit_result = factorial[n_digit] * inverse_factorial[k_digit]
                          % prime;
        digit_result = digit_result * inverse_factorial[n_digit - k_digit]
                     % prime;
        result = result * digit_result % prime;
        n = n / prime;
        k = k / prime;
    }
    return result;
}
