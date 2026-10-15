/* Reverse the bit order of an unsigned 32-bit word. */
#include <stdint.h>

int64_t reverse_bits(int64_t value)
{
    if (value < 0 || (uint64_t)value > UINT32_MAX) return -1;
    uint32_t remaining = (uint32_t)value;
    uint32_t reversed = 0;
    for (unsigned bit = 0; bit < 32; ++bit) {
        reversed = (reversed << 1) | (remaining & UINT32_C(1));
        remaining >>= 1;
    }
    return (int64_t)reversed;
}
