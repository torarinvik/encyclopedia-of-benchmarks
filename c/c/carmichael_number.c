#include <stdint.h>

static int is_composite(int64_t n)
{
    if (n < 4) return 0;
    for (int64_t divisor = 2; divisor <= n / divisor; ++divisor) {
        if (n % divisor == 0) return 1;
    }
    return 0;
}

static int64_t modular_power(int64_t base, int64_t exponent, int64_t modulus)
{
    if (exponent == 0) return 1;
    int64_t half = modular_power(base, exponent / 2, modulus) % modulus;
    int64_t result = (half * half) % modulus;
    if (exponent % 2 != 0) result = (result * base) % modulus;
    return result;
}

static int64_t gcd(int64_t left, int64_t right)
{
    while (right != 0) {
        int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t carmichael_number(int64_t value)
{
    if (value < 1 || value > 10000) return -1;
    if (value < 3 || !is_composite(value)) return 0;
    for (int64_t base = 2; base < value; ++base) {
        if (gcd(base, value) == 1 && modular_power(base, value - 1, value) != 1) return 0;
    }
    return 1;
}
