#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 22, MAX_PARSEABLE_LENGTH = 2 };

static int64_t wn_gcd(int64_t a, int64_t b) {
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int64_t wn_numerator(int64_t n) {
    int64_t numerator = 0;
    int64_t denominator = 1;
    for (int64_t k = 1; k <= n; ++k) {
        const int64_t square = k * k;
        const int64_t common = wn_gcd(denominator, square);
        const int64_t scale = square / common;
        numerator = numerator * scale + denominator / common;
        denominator *= scale;
        const int64_t reduce_by = wn_gcd(numerator, denominator);
        numerator /= reduce_by;
        denominator /= reduce_by;
    }
    return numerator;
}

int64_t wolstenholme_numbers(const int64_t *input, size_t length) {
    if (input == NULL || length < 1U || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 1U || input[0] < 1 || input[0] > MAX_N) return -1;
    return wn_numerator(input[0]);
}
