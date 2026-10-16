/* Return the unpadded decimal suffix of the non-Mersenne prime expression. */
#include <stdint.h>

#define MAX_DIGITS INT64_C(18)
#define POWER_EXPONENT INT64_C(7830457)

static int64_t multiply_mod(int64_t left, int64_t right, int64_t modulus)
{
    int64_t result = 0;
    while (right > 0) {
        if (right % 2 != 0) result = (result + left) % modulus;
        left = (left + left) % modulus;
        right /= 2;
    }
    return result;
}

int64_t problem97(int64_t digits)
{
    if (digits < 0 || digits > MAX_DIGITS) return -1;
    int64_t modulus = 1;
    for (int64_t index = 0; index < digits; ++index) modulus *= 10;
    int64_t power = 1 % modulus;
    int64_t base = 2 % modulus;
    int64_t exponent = POWER_EXPONENT;
    while (exponent > 0) {
        if (exponent % 2 != 0) power = multiply_mod(power, base, modulus);
        base = multiply_mod(base, base, modulus);
        exponent /= 2;
    }
    return (multiply_mod(28433, power, modulus) + 1) % modulus;
}
