#include <stdint.h>

static int64_t normalized_mod(int64_t value, int64_t modulus)
{
    int64_t remainder = value % modulus;
    if (remainder < 0) remainder += modulus;
    return remainder;
}

int64_t modular_inverse(int64_t a, int64_t modulus)
{
    if (a < 0 || a > 1000000 || modulus < 2 || modulus > 1000000) return -1;

    int64_t old_remainder = normalized_mod(a, modulus);
    int64_t remainder = modulus;
    int64_t old_coefficient = 1;
    int64_t coefficient = 0;
    while (remainder != 0) {
        const int64_t quotient = old_remainder / remainder;
        const int64_t next_remainder = old_remainder - quotient * remainder;
        const int64_t next_coefficient = old_coefficient - quotient * coefficient;
        old_remainder = remainder;
        remainder = next_remainder;
        old_coefficient = coefficient;
        coefficient = next_coefficient;
    }
    if (old_remainder != 1) return -1;
    return normalized_mod(old_coefficient, modulus);
}
