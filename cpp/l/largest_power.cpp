// Legendre's formula for the exponent of prime p in n!.
#include <cstdint>

static bool largest_power_is_prime(uint64_t value)
{
    if (value < 2) return false;
    for (uint64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor == 0) return false;
    }
    return true;
}

extern "C" int64_t largest_power(uint64_t n, uint64_t p)
{
    if (n > UINT32_MAX || p > UINT16_MAX || !largest_power_is_prime(p)) return -1;
    uint64_t quotient = n;
    int64_t total = 0;
    while (quotient != 0) {
        quotient /= p;
        total += static_cast<int64_t>(quotient);
    }
    return total;
}
