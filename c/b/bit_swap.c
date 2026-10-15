/* Swap two 0-based bits in a signed 32-bit value. */
#include <stddef.h>
#include <stdint.h>

static int64_t sign_extend_u32(uint32_t bits)
{
    return bits <= INT32_MAX ? (int64_t)bits : (int64_t)bits - INT64_C(4294967296);
}

int64_t bit_swap(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return -INT64_C(2147483649);
    const int64_t data = values[0];
    const int64_t pos_a = values[1];
    const int64_t pos_b = values[2];
    if (data < INT32_MIN || data > INT32_MAX || pos_a < 0 || pos_a >= 32 || pos_b < 0 || pos_b >= 32)
        return -INT64_C(2147483649);
    uint32_t bits = (uint32_t)(int32_t)data;
    const uint32_t mask_a = UINT32_C(1) << (unsigned)pos_a;
    const uint32_t mask_b = UINT32_C(1) << (unsigned)pos_b;
    const uint32_t bit_a = (bits >> (unsigned)pos_a) & UINT32_C(1);
    const uint32_t bit_b = (bits >> (unsigned)pos_b) & UINT32_C(1);
    if (bit_a != bit_b) bits ^= mask_a ^ mask_b;
    return sign_extend_u32(bits);
}
