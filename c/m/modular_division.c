/* Fermat modular division for a bounded prime modulus. */
#include <stddef.h>
#include <stdint.h>

static int is_prime(int64_t value)
{
    if (value < 2) return 0;
    for (int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

static int64_t modular_power(int64_t base, uint64_t exponent, int64_t modulus)
{
    int64_t result = 1;
    base %= modulus;
    while (exponent != 0) {
        if ((exponent & 1U) != 0) result = (result * base) % modulus;
        exponent >>= 1;
        base = (base * base) % modulus;
    }
    return result;
}

int64_t modular_division(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return -1;
    const int64_t numerator = values[0];
    const int64_t denominator = values[1];
    const int64_t modulus = values[2];
    if (numerator < 0 || numerator > INT64_C(1000000000000) ||
        denominator < 0 || denominator > INT64_C(1000000000000) ||
        modulus < 2 || modulus > 1000000 || !is_prime(modulus) ||
        denominator % modulus == 0) return -1;
    const int64_t inverse = modular_power(denominator, (uint64_t)(modulus - 2), modulus);
    return ((numerator % modulus) * inverse) % modulus;
}
