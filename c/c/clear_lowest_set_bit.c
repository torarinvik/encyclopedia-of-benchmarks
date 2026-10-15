#include <stdint.h>

int64_t clear_lowest_set_bit(int64_t value)
{
    if (value < 0 || value > INT32_MAX) return -1;
    return value & (value - 1);
}
