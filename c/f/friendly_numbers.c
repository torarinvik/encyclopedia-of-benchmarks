/* Preserve the pinned JavaScript FriendlyNumbers divisor-loop behavior. */
#include <stdint.h>

#define MAX_INPUT UINT64_C(1000)

static double abundancy_index(uint64_t number)
{
    uint64_t sum = number;
    for (uint64_t divisor = 1; divisor * 2 < number; ++divisor)
        if (number % divisor == 0) sum += divisor;
    return (double)sum / (double)number;
}

int64_t friendly_numbers(uint64_t first, uint64_t second)
{
    if (first == 0 || second == 0 || first == second ||
        first > MAX_INPUT || second > MAX_INPUT) return -1;
    return abundancy_index(first) == abundancy_index(second) ? 1 : 0;
}
