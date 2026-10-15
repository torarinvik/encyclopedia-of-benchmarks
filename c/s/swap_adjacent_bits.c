/* Exchange each adjacent pair of low 30 bits. */
#include <stdint.h>

int64_t swap_adjacent_bits(int64_t input)
{
    if (input < 0 || input > INT64_C(1073741823)) return -1;
    const uint32_t value = (uint32_t)input;
    return (int64_t)(((value & UINT32_C(0xAAAAAAAA)) >> 1)
        | ((value & UINT32_C(0x55555555)) << 1));
}
