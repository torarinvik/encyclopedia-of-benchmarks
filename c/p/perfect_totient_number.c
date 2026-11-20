/* Decide whether the iterated Euler-totient chain sums to n. */
#include <stdint.h>

static int64_t totient(int64_t value)
{
    int64_t result = value;
    int64_t remaining = value;
    for (int64_t factor = 2; factor <= remaining / factor; ++factor) {
        if (remaining % factor == 0) {
            do { remaining /= factor; } while (remaining % factor == 0);
            result -= result / factor;
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}

int64_t perfect_totient_number(int64_t n)
{
    if (n < 3 || n > 65535) return -1;
    int64_t value = n;
    int64_t sum = 0;
    while (value > 1) {
        value = totient(value);
        sum += value;
    }
    return sum == n ? 1 : 0;
}
