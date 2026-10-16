#include <stdint.h>

static int64_t divisor_count(int64_t value)
{
    int64_t count = 1;
    for (int64_t factor = 2; factor <= value / factor; ++factor) {
        if (value % factor == 0) {
            int64_t exponent = 0;
            do {
                value /= factor;
                ++exponent;
            } while (value % factor == 0);
            count *= exponent + 1;
        }
    }
    if (value > 1) count *= 2;
    return count;
}

int64_t problem12(int64_t minimum_divisors)
{
    if (minimum_divisors < 0 || minimum_divisors > 500) return -1;
    for (int64_t index = 1; index <= 12375; ++index) {
        int64_t left = index;
        int64_t right = index + 1;
        if (index % 2 == 0) left /= 2;
        else right /= 2;
        if (divisor_count(left) * divisor_count(right) >= minimum_divisors)
            return index * (index + 1) / 2;
    }
    return -1;
}
