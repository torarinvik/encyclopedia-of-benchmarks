#include <stdint.h>

static int64_t modexpt(int64_t base, int64_t exponent, int64_t modulus)
{
    if (exponent == 1) return base;
    if (exponent % 2 == 0) {
        const int64_t half = modexpt(base, exponent / 2, modulus) % modulus;
        return (half * half) % modulus;
    }
    return (base * modexpt(base, exponent - 1, modulus)) % modulus;
}

int64_t problem188(int64_t base, int64_t height, int64_t digits)
{
    if (base < 1 || base > 1000000000 || base % 10 == 0
        || height < 1 || height > 10000 || digits < 1 || digits > 8) return -1;
    int64_t modulus = 1;
    for (int64_t index = 0; index < digits; ++index) modulus *= 10;
    int64_t result = base;
    for (int64_t level = 1; level < height; ++level)
        result = modexpt(base, result, modulus);
    return result;
}
