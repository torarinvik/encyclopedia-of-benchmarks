/* Portable factorial for the shared signed 64-bit benchmark contract. */
#include <stdint.h>

int64_t factorial(int64_t n)
{
    if (n < 0 || n > 20) {
        return -1;
    }

    int64_t product = 1;
    for (int64_t factor = 2; factor <= n; ++factor) {
        product *= factor;
    }
    return product;
}
