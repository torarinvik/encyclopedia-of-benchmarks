#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-2)
#define MAX_VALUE 1000000000000LL

static int64_t decimal_exponent(int64_t base) {
    if (base < 1) return -1;
    int64_t exponent = 0;
    while (base > 1 && base % 10 == 0) {
        base /= 10;
        ++exponent;
    }
    return base == 1 ? exponent : -1;
}

static int valid_base(int64_t base) {
    return base == 0 || decimal_exponent(base) >= 0;
}

static int64_t source_score(int64_t base, int64_t exponent) {
    if (base == 0) return 0;
    if (exponent == 0) return 1;
    return decimal_exponent(base) * exponent;
}

int64_t largest_of_very_large_numbers(const int64_t *values, size_t length) {
    if (values == NULL || length != 4) return INVALID_RESULT;
    for (size_t i = 0; i < 4; ++i) if (values[i] < 0 || values[i] > MAX_VALUE) return INVALID_RESULT;
    if (!valid_base(values[0]) || !valid_base(values[2])) return INVALID_RESULT;
    const int64_t score_a = source_score(values[0], values[1]);
    const int64_t score_b = source_score(values[2], values[3]);
    return (score_a > score_b) - (score_a < score_b);
}
