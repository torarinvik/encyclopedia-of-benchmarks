/* Return the one-based position of the least significant set bit. */
#include <stdint.h>

int64_t rightmost_set_bit(int64_t value)
{
    if (value <= 0 || value > INT32_MAX) return -1;
    uint32_t lowest = (uint32_t)value & (0u - (uint32_t)value);
    int64_t position = 1;
    while ((lowest & 1u) == 0u) {
        lowest >>= 1;
        ++position;
    }
    return position;
}
