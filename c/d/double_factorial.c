/* Iterative double factorial for the signed 64-bit benchmark contract. */
#include <stdint.h>

int64_t double_factorial(int64_t n)
{
    if (n < 0 || n > 33) return -1;
    int64_t result = 1;
    for (int64_t factor = n; factor > 1; factor -= 2) result *= factor;
    return result;
}
