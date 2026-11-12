/* Infinite geometric-weighted power sum via an Eulerian polynomial row. */
#include <stddef.h>
#include <stdint.h>

#define SEPPL_MOD INT64_C(998244353)
#define SEPPL_MAX_DEGREE 256

static int64_t seppl_mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % SEPPL_MOD;
        base = base * base % SEPPL_MOD;
        exponent >>= 1;
    }
    return result;
}

int64_t sum_of_exponential_times_polynomial_limit(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t r = input[0];
    const int64_t degree_value = input[1];
    if (r < 0 || r >= SEPPL_MOD || r == 1 || degree_value < 0 || degree_value > SEPPL_MAX_DEGREE) return -1;
    const size_t degree = (size_t)degree_value;
    const int64_t denominator = (1 - r + SEPPL_MOD) % SEPPL_MOD;
    const int64_t inverse = seppl_mod_pow(denominator, SEPPL_MOD - 2);
    if (degree == 0) return inverse;

    int64_t row[SEPPL_MAX_DEGREE + 1] = {0};
    int64_t next[SEPPL_MAX_DEGREE + 1] = {0};
    row[0] = 1;
    for (size_t n = 1; n <= degree; ++n) {
        for (size_t k = 0; k <= n; ++k) {
            int64_t value = 0;
            if (k > 0) value += (int64_t)(n - k) * row[k - 1];
            if (k < n) value += (int64_t)(k + 1) * row[k];
            next[k] = value % SEPPL_MOD;
        }
        for (size_t k = 0; k <= n; ++k) {
            row[k] = next[k];
            next[k] = 0;
        }
    }

    int64_t eulerian_value = 0;
    for (size_t k = degree; k > 0; --k) {
        eulerian_value = (eulerian_value * r + row[k - 1]) % SEPPL_MOD;
    }
    const int64_t denominator_power = seppl_mod_pow(inverse, (int64_t)degree + 1);
    return r * eulerian_value % SEPPL_MOD * denominator_power % SEPPL_MOD;
}
