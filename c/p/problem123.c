/* Find the first odd prime index whose source remainder exceeds the limit. */
#include <stdint.h>

#define MAX_LIMIT INT64_C(10000000000)
#define PRIME_LIMIT 300000

int64_t problem123(int64_t limit)
{
    if (limit > MAX_LIMIT) return -1;
    uint8_t composite[PRIME_LIMIT + 1] = {0};
    for (int64_t factor = 2; factor * factor <= PRIME_LIMIT; ++factor)
        if (!composite[factor])
            for (int64_t multiple = factor * factor; multiple <= PRIME_LIMIT; multiple += factor)
                composite[multiple] = 1;
    int64_t n = 1;
    int skip_next = 0;
    for (int64_t candidate = 2; candidate <= PRIME_LIMIT; ++candidate) {
        if (composite[candidate]) continue;
        if (skip_next) { skip_next = 0; continue; }
        if (2 * candidate * n > limit) return n;
        skip_next = 1;
        n += 2;
    }
    return -1;
}
