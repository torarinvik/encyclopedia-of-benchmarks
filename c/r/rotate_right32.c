#include <stdint.h>

int64_t rotate_right32(uint64_t value, uint64_t shift)
{
    if (value > UINT32_MAX || shift > INT32_MAX) return -1;
    const uint32_t bits = (uint32_t)value;
    const uint32_t amount = (uint32_t)(shift % 32);
    if (amount == 0) return (int64_t)bits;
    return (int64_t)((bits >> amount) | (bits << (32 - amount)));
}
