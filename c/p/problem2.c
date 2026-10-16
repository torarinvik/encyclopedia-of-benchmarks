#include <stdint.h>

int64_t problem2(int64_t limit)
{
    if (limit < 0 || limit > 4000000) return -1;
    int64_t previous = 1;
    int64_t current = 2;
    int64_t sum = 0;
    while (current < limit) {
        if (current % 2 == 0) sum += current;
        int64_t next = previous + current;
        previous = current;
        current = next;
    }
    return sum;
}
