/* Java int addition by recursive XOR and shifted carry, modulo 2^32. */
#include <stdint.h>

static uint32_t add_recursive(uint32_t a, uint32_t b)
{
    if (b == 0) return a;
    return add_recursive(a ^ b, (a & b) << 1);
}

static int64_t signed_result(uint32_t bits)
{
    return bits <= INT32_MAX ? (int64_t)bits : (int64_t)bits - INT64_C(4294967296);
}

int64_t sum_without_arithmetic_operators(int64_t a, int64_t b)
{
    if (a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX) return -INT64_C(2147483649);
    return signed_result(add_recursive((uint32_t)a, (uint32_t)b));
}
