/* Count ways to climb n stairs using one or two steps per move. */
#include <stdint.h>

int64_t climbing_stairs(int64_t steps)
{
    if (steps < 1 || steps > 45) return -1;
    int64_t previous = 1;
    int64_t current = 1;
    for (int64_t index = 2; index <= steps; ++index) {
        const int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return current;
}
