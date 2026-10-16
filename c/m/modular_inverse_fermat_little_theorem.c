#include <stdint.h>

static int64_t binary_exponentiation(int64_t base, int64_t exponent, int64_t modulus)
{
    base %= modulus;
    int64_t result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

static int is_prime(int64_t value)
{
    if (value <= 1) return 0;
    for (int64_t divisor = 2; divisor * divisor <= value; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t modular_inverse_fermat_little_theorem(int64_t a, int64_t m)
{
    if (a < 1 || a > 1000000 || m < 2 || m > 1000000 ||
        a % m == 0 || !is_prime(m)) return -1;
    return binary_exponentiation(a, m - 2, m);
}
