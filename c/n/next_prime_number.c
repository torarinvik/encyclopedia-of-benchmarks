/* Find the smallest prime strictly greater than the input. */
#include <stdint.h>

static int is_candidate_prime(uint32_t value)
{
    if (value % 3 == 0) return 0;
    for (uint32_t divisor = 5; divisor * divisor <= value; divisor += 6) {
        if (value % divisor == 0 || value % (divisor + 2) == 0) return 0;
    }
    return 1;
}

int64_t next_prime_number(int64_t value)
{
    if (value < -4096 || value > 4096) return -1;
    if (value < 2) return 2;
    if (value == 2) return 3;
    uint32_t candidate = (uint32_t)(value + 1) | 1;
    while (!is_candidate_prime(candidate)) candidate += 2;
    return candidate;
}
