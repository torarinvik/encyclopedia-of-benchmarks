/* Rotate an unsigned 53-bit integer left by 0 through 53 positions. */
#include <stdint.h>

int64_t circular_left_shift(uint64_t value, uint64_t shift)
{
    const uint64_t mask = UINT64_C(9007199254740991);
    if (value > mask || shift > 53) return -1;
    const unsigned amount = (unsigned)shift;
    const uint64_t low = (value & (mask >> amount)) << amount;
    const uint64_t high = value >> (53 - amount);
    return (int64_t)(low | high);
}
