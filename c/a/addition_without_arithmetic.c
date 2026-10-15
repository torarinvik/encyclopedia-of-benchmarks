#include <stdint.h>

static int64_t signed_sum_from_bits(uint32_t bits)
{
    if (bits <= INT32_MAX) return (int64_t)bits;
    return (int64_t)bits - INT64_C(4294967296);
}

static int is_signed_i32_encoding(uint64_t value)
{
    return value <= INT32_MAX || value >= UINT64_MAX - INT32_MAX;
}

int64_t addition_without_arithmetic(uint64_t left_encoded, uint64_t right_encoded)
{
    if (!is_signed_i32_encoding(left_encoded) || !is_signed_i32_encoding(right_encoded)) return -1;
    const int64_t left_value = signed_sum_from_bits((uint32_t)left_encoded);
    const int64_t right_value = signed_sum_from_bits((uint32_t)right_encoded);
    uint32_t left = (uint32_t)left_encoded;
    uint32_t right = (uint32_t)right_encoded;
    while (right != 0) {
        const uint32_t carry = left & right;
        left ^= right;
        right = carry << 1;
    }
    const int64_t result = signed_sum_from_bits(left);
    if ((left_value < 0) == (right_value < 0) && (result < 0) != (left_value < 0)) return -1;
    return result;
}
