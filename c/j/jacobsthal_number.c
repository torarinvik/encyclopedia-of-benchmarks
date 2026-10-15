/* Return J(n) for the bounded signed-64-bit Jacobsthal index. */
#include <stdint.h>

int64_t jacobsthal_number(int64_t n)
{
    if (n < 0 || n > 64) return -1;
    if (n == 0) return 0;
    int64_t previous = 0;
    int64_t current = 1;
    for (int64_t index = 2; index <= n; ++index) {
        const int64_t next = current + 2 * previous;
        previous = current;
        current = next;
    }
    return current;
}
