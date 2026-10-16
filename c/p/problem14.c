#include <stdint.h>

#define MAX_LIMIT INT64_C(1000000)
#define MAX_CHAIN_LENGTH UINT64_C(10000)
#define MAX_SAFE_ODD UINT64_C(6148914691236517204)

static uint64_t collatz_length(uint64_t start)
{
    uint64_t current = start;
    uint64_t length = 1;
    while (current != 1) {
        if (length >= MAX_CHAIN_LENGTH) return 0;
        if (current % 2 == 0) current /= 2;
        else {
            if (current > MAX_SAFE_ODD) return 0;
            current = 3 * current + 1;
        }
        ++length;
    }
    return length;
}

int64_t problem14(int64_t limit)
{
    if (limit < 1 || limit > MAX_LIMIT) return -1;
    uint64_t best_start = 1;
    uint64_t best_length = 1;
    for (uint64_t start = 2; start <= (uint64_t)limit; ++start) {
        const uint64_t length = collatz_length(start);
        if (length == 0) return -1;
        if (length > best_length) {
            best_start = start;
            best_length = length;
        }
    }
    return (int64_t)best_start;
}
