/* Portable Fibonacci for the shared signed 64-bit benchmark contract. */
#include <stdint.h>

int64_t fibonacci(int64_t n)
{
    if (n < 0 || n > 92) {
        return -1;
    }
    if (n == 0) {
        return 0;
    }

    int64_t previous = 0;
    int64_t current = 1;
    for (int64_t index = 1; index < n; ++index) {
        const int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}
