#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-2)
#define MAX_VALUE 1000000000000LL

static double source_score(int64_t base, int64_t exponent) {
    if (base == 0) return 0.0;
    if (exponent == 0) return 1.0;
    return (double)exponent * log10((double)base);
}

static int valid_comparison_domain(int64_t base_a, int64_t exponent_a,
                                   int64_t base_b, int64_t exponent_b) {
    return exponent_a == exponent_b ||
           (base_a == base_b &&
            (base_a == 0 || ((exponent_a == 0) == (exponent_b == 0))));
}

int64_t largest_of_very_large_numbers(const int64_t *values, size_t length) {
    if (values == NULL || length != 4) return INVALID_RESULT;
    for (size_t i = 0; i < 4; ++i) if (values[i] < 0 || values[i] > MAX_VALUE) return INVALID_RESULT;
    if (!valid_comparison_domain(values[0], values[1], values[2], values[3])) return INVALID_RESULT;
    const double score_a = source_score(values[0], values[1]);
    const double score_b = source_score(values[2], values[3]);
    return (score_a > score_b) - (score_a < score_b);
}
