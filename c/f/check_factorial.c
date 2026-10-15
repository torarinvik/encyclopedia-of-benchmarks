/* Return 1 when n is exactly k! for some k >= 0; otherwise return 0. */
#include <stdint.h>

int64_t check_factorial(int64_t n)
{
    if (n <= 0) return 0;
    int64_t value = n;
    int64_t divisor = 2;
    while (value % divisor == 0) {
        value /= divisor;
        ++divisor;
    }
    return value == 1 ? 1 : 0;
}
