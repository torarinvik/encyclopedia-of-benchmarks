/* Bounded port of TheAlgorithms/Python Project Euler 38 search. */
#include <stdint.h>

static int is_9_pandigital(int64_t value)
{
    if (value < 100000000 || value > 999999999) return 0;
    unsigned int mask = 0;
    while (value > 0) {
        const unsigned int digit = (unsigned int)(value % 10);
        if (digit == 0 || (mask & (1u << digit)) != 0) return 0;
        mask |= 1u << digit;
        value /= 10;
    }
    return mask == 0x3feu;
}

int64_t problem38(int64_t unused)
{
    if (unused != 0) return -1;
    for (int64_t base = 9999; base > 4999; --base) {
        const int64_t candidate = 100002 * base;
        if (is_9_pandigital(candidate)) return candidate;
    }
    for (int64_t base = 333; base > 99; --base) {
        const int64_t candidate = 1002003 * base;
        if (is_9_pandigital(candidate)) return candidate;
    }
    return -1;
}
