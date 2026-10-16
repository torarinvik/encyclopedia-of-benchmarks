#include <stdint.h>

/* Preserve the Go source's direct square-and-last-digit loop. */
int64_t isautomorphic(int64_t n)
{
    const int64_t max_safe = INT64_C(3037000499);
    if (n < -max_safe || n > max_safe) return -1;
    if (n < 0) return 0;

    int64_t square = n * n;
    int64_t remaining = n;
    while (remaining > 0) {
        if (remaining % 10 != square % 10) return 0;
        remaining /= 10;
        square /= 10;
    }
    return 1;
}
