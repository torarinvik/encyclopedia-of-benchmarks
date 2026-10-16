#include <stdint.h>

int64_t problem137(int64_t n)
{
    if (n < 1 || n > 23) return -1;
    int64_t previous = 1;
    int64_t current = 1;
    for (int64_t index = 0; index < 2 * n - 1; ++index) {
        const int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return previous * current;
}
