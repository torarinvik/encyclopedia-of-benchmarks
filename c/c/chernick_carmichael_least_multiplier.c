#include <stddef.h>
#include <stdint.h>

#define MAX_MULTIPLIER INT64_C(950560)

static int is_prime(int64_t value)
{
    if (value < 2) return 0;
    if (value % 2 == 0) return value == 2;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int has_prime_factors(int64_t n, int64_t multiplier)
{
    if (!is_prime(6 * multiplier + 1) || !is_prime(12 * multiplier + 1)) return 0;
    const int64_t base = 9 * multiplier;
    for (int64_t exponent = 1; exponent <= n - 2; ++exponent) {
        if (!is_prime(base * (INT64_C(1) << exponent) + 1)) return 0;
    }
    return 1;
}

int64_t chernick_carmichael_least_multiplier(const int64_t *input, size_t length)
{
    if (input == NULL || length != 1) return -1;
    const int64_t n = input[0];
    if (n < 3 || n > 9) return -1;

    int64_t step = 1;
    if (n > 4) step = INT64_C(1) << (n - 4);
    if (n > 5) step *= 5;

    for (int64_t multiplier = step; multiplier <= MAX_MULTIPLIER;
         multiplier += step) {
        if (has_prime_factors(n, multiplier)) return multiplier;
    }
    return -1;
}
