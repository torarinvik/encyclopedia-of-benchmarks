/* Count transitions in the classic Collatz sequence for a bounded input. */
#include <stdint.h>

int64_t collatz(int64_t n)
{
    if (n < 1 || n > 1000000) return -1;
    int64_t steps = 0;
    while (n != 1) {
        if (n % 2 == 0) n /= 2;
        else n = 3 * n + 1;
        ++steps;
    }
    return steps;
}
