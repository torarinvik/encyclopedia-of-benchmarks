#include <stdint.h>

int64_t count_leading_zeros(int64_t value)
{
    if (value < INT32_MIN || value > INT32_MAX) return -1;
    if (value == 0) return 32;
    int64_t mask = INT64_C(1) << 31;
    int64_t count = 0;
    while ((mask & value) == 0) {
        ++count;
        mask >>= 1;
    }
    return count;
}
