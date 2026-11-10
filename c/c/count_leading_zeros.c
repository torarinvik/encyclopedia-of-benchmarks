#include <stdint.h>

int64_t count_leading_zeros(int64_t value)
{
    if (value < INT32_MIN || value > INT32_MAX) return -1;
    uint32_t bits = (uint32_t)value;
    return bits == 0 ? 32 : __builtin_clz(bits);
}
