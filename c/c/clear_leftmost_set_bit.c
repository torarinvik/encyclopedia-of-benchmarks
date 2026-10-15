#include <stdint.h>

int64_t clear_leftmost_set_bit(int64_t value)
{
    if (value < 0 || value > INT32_MAX) return -1;
    if (value == 0) return 0;
    int64_t temp = value;
    int64_t position = 0;
    while (temp > 0) {
        temp >>= 1;
        ++position;
    }
    const int64_t mask = ~(INT64_C(1) << (position - 1));
    return value & mask;
}
