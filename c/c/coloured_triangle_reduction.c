/* Lucas-based closed form for repeated -(left + right) mod 3 reduction. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(256)
#define MAX_PARSEABLE_LENGTH ((size_t)258)

static int64_t binomial_mod_three(int64_t n, int64_t k) {
    int64_t coefficient = 1;
    while (n > 0 || k > 0) {
        const int64_t n_digit = n % 3;
        const int64_t k_digit = k % 3;
        if (k_digit > n_digit) return 0;
        if (n_digit == 2 && k_digit == 1) coefficient = (2 * coefficient) % 3;
        n /= 3;
        k /= 3;
    }
    return coefficient;
}

int64_t coloured_triangle_reduction(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n = input[0];
    if (n < 1 || n > MAX_N || length != (size_t)(n + 1)) return -1;
    for (size_t index = 0; index < (size_t)n; ++index)
        if (input[index + 1] < 0 || input[index + 1] > 2) return -1;

    const int64_t rounds = n - 1;
    int64_t total = 0;
    for (int64_t index = 0; index < n; ++index) {
        total = (total + binomial_mod_three(rounds, index) * input[index + 1]) % 3;
    }
    return rounds % 2 == 0 ? total : (3 - total) % 3;
}
