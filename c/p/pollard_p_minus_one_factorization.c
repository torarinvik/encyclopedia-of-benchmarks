#include <stddef.h>
#include <stdint.h>

static const int64_t SMALL_PRIMES[] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61};

static int64_t gcd_i64(int64_t left, int64_t right) {
    while (right != 0) {
        const int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

static int64_t pow_mod_i64(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

int64_t pollard_p_minus_one_factorization(const int64_t *input, size_t length) {
    if (input == NULL || length != 3) return -1;
    const int64_t number = input[0], bound = input[1], initial = input[2];
    if (number < 2 || number > 1000000000 || bound < 2 || bound > 64 || initial < 1 || initial >= number) return -1;
    int64_t divisor = gcd_i64(initial, number);
    if (divisor > 1) return divisor;

    int64_t state = initial;
    for (size_t i = 0; i < sizeof(SMALL_PRIMES) / sizeof(SMALL_PRIMES[0]); ++i) {
        const int64_t prime = SMALL_PRIMES[i];
        if (prime > bound) break;
        int64_t exponent = prime;
        while (exponent <= bound / prime) exponent *= prime;
        state = pow_mod_i64(state, exponent, number);
        const int64_t difference = state >= 1 ? state - 1 : 1 - state;
        divisor = gcd_i64(difference, number);
        if (divisor > 1) return divisor < number ? divisor : 0;
    }
    return 0;
}
