#include <stddef.h>
#include <stdint.h>
#include <math.h>

enum { MAX_PAIR_COUNT = 1000, MAX_BASE = 1000000, MAX_EXPONENT = 1200000 };

int64_t problem99(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1) return -1;
    const int64_t pair_count_value = input[0];
    if (pair_count_value < 0 || pair_count_value > MAX_PAIR_COUNT) return -1;
    const size_t pair_count = (size_t)pair_count_value;
    if (length != 1 + 2 * pair_count) return -1;

    double largest = 0.0;
    int64_t result = 0;
    for (size_t index = 0; index < pair_count; ++index) {
        const int64_t base = input[1 + 2 * index];
        const int64_t exponent = input[2 + 2 * index];
        if (base < 1 || base > MAX_BASE || exponent < 0 || exponent > MAX_EXPONENT) return -1;
        const double value = (double)exponent * log10((double)base);
        if (value > largest) {
            largest = value;
            result = (int64_t)index + 1;
        }
    }
    return result;
}
