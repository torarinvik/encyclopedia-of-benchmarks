/* Liouville's function: (-1) raised to the number of prime factors with multiplicity. */
#include <stdint.h>

int64_t liouville_lambda(int64_t input)
{
    if (input < 1 || input > 2147483647) return -1;
    uint64_t remaining = (uint64_t)input;
    int64_t sign = 1;
    for (uint64_t factor = 2; factor <= remaining / factor;
         factor += factor == 2 ? 1 : 2) {
        while (remaining % factor == 0) {
            remaining /= factor;
            sign = -sign;
        }
    }
    if (remaining > 1) sign = -sign;
    return sign;
}
