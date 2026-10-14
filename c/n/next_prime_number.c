/* Find the smallest prime strictly greater than the input. */
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

int64_t next_prime_number(int64_t value)
{
    if (value < -4096 || value > 4096) return -1;
    int64_t candidate = value + 1;
    if (candidate < 2) candidate = 2;
    while (!is_prime(candidate)) ++candidate;
    return candidate;
}
