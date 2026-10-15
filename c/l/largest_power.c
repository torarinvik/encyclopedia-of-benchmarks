/* Legendre's formula for the exponent of prime p in n!. */
#include <stdint.h>

static int is_prime(uint64_t value)
{
    if (value < 2) return 0;
    for (uint64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t largest_power(uint64_t n, uint64_t p)
{
    if (n > UINT32_MAX || p > UINT16_MAX || !is_prime(p)) return -1;
    uint64_t quotient = n;
    int64_t total = 0;
    while (quotient != 0) {
        quotient /= p;
        total += (int64_t)quotient;
    }
    return total;
}
