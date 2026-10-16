#include <stdint.h>

enum { MAX_LIMIT = 1000 };

int64_t problem120(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    int64_t total = 0;
    for (int64_t a = 3; a <= limit; ++a) total += 2 * a * ((a - 1) / 2);
    return total;
}
