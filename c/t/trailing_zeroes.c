/* Count decimal zero digits at the end of a nonnegative integer. */
#include <stdint.h>

int64_t trailing_zeroes(int64_t n)
{
    if (n < 0) return -1;
    if (n == 0) return 1;
    int64_t count = 0;
    while (n % 10 == 0) {
        ++count;
        n /= 10;
    }
    return count;
}
