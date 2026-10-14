/* Check whether the square ends with the original nonnegative integer. */
#include <stdint.h>

static uint64_t add_mod(uint64_t left, uint64_t right, uint64_t modulus)
{
    return left >= modulus - right ? left - (modulus - right) : left + right;
}

static uint64_t multiply_mod(uint64_t left, uint64_t right, uint64_t modulus)
{
    uint64_t result = 0;
    while (right != 0) {
        if ((right & 1u) != 0) result = add_mod(result, left, modulus);
        right >>= 1;
        if (right != 0) left = add_mod(left, left, modulus);
    }
    return result;
}

int64_t automorphic_number(int64_t n)
{
    if (n < 0) return 0;
    const uint64_t number = (uint64_t)n;
    uint64_t modulus = 10;
    for (uint64_t digits = number; digits >= 10; digits /= 10) modulus *= 10;
    return multiply_mod(number, number, modulus) == number ? 1 : 0;
}
