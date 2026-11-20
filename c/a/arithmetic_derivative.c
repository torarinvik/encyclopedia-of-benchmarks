#include <stddef.h>
#include <stdint.h>

enum { MAX_PARSEABLE_LENGTH = 2 };
static const int64_t MAX_N = INT64_C(1000000000000);

static int64_t derivative_from_factors(int64_t n) {
    if (n < 2) return 0;
    const int64_t original = n;
    int64_t derivative = 0;
    int64_t factor = 2;
    while (factor <= n / factor) {
        if (n % factor == 0) {
            int64_t exponent = 0;
            do {
                n /= factor;
                ++exponent;
            } while (n % factor == 0);
            derivative += (original / factor) * exponent;
        }
        factor = factor == 2 ? 3 : factor + 2;
    }
    if (n > 1) derivative += original / n;
    return derivative;
}

int64_t arithmetic_derivative(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1) return -1;
    const int64_t n = input[0];
    if (n < 0 || n > MAX_N) return -1;
    return derivative_from_factors(n);
}
