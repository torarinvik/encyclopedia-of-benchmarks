#include <stdint.h>

static int problem27_is_prime(int64_t value)
{
    if (value < 2) return 0;
    if (value % 2 == 0) return value == 2;
    if (value % 3 == 0) return value == 3;
    for (int64_t factor = 5; factor <= value / factor; factor += 6) {
        if (value % factor == 0 || value % (factor + 2) == 0) return 0;
    }
    return 1;
}

int64_t problem27(int64_t limit)
{
    if (limit < 1 || limit > 1000) return -1;
    int64_t best_length = 0;
    int64_t best_a = 0;
    int64_t best_b = 0;
    for (int64_t a = 1 - limit; a < limit; ++a) {
        for (int64_t b = 2; b < limit; ++b) {
            if (!problem27_is_prime(b)) continue;
            int64_t n = 0;
            while (problem27_is_prime(n * n + a * n + b)) ++n;
            if (n > best_length) {
                best_length = n;
                best_a = a;
                best_b = b;
            }
        }
    }
    return best_a * best_b;
}
