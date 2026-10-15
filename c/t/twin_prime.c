/* Return n + 2 when n and n + 2 are twin primes, otherwise -1. */
#include <stdint.h>

static int is_prime(int64_t value)
{
    if (value < 2) return 0;
    if (value == 2) return 1;
    if (value % 2 == 0) return 0;
    for (int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return 0;
    }
    return 1;
}

int64_t twin_prime(int64_t value)
{
    if (value < -4096 || value > 4096) return -1;
    return is_prime(value) && is_prime(value + 2) ? value + 2 : -1;
}
