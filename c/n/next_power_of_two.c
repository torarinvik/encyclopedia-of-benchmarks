/* Bit spreading for the pinned positive 32-bit source domain. */
#include <stdint.h>

int64_t next_power_of_two(int64_t number)
{
    if (number < 1 || number > 1073741824) return -1;
    uint64_t value = (uint64_t)number;
    if ((value & (value - 1)) == 0) return number;

    value -= 1;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return (int64_t)(value + 1);
}
