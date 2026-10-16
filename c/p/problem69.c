/* Totient-table maximum ratio search for Project Euler 69. */
#include <stdint.h>
#include <stdlib.h>

enum { MAX_LIMIT = 1000000 };

int64_t problem69(int64_t inclusive_limit)
{
    if (inclusive_limit < 1 || inclusive_limit > MAX_LIMIT) return -1;
    const size_t limit = (size_t)inclusive_limit;
    uint32_t *phi = (uint32_t *)calloc(limit + 1, sizeof(uint32_t));
    if (phi == NULL) return -1;
    for (size_t value = 0; value <= limit; ++value) phi[value] = (uint32_t)value;
    for (size_t number = 2; number <= limit; ++number) {
        if (phi[number] != number) continue;
        --phi[number];
        for (size_t multiple = number * 2; multiple <= limit; multiple += number) {
            phi[multiple] = (phi[multiple] / (uint32_t)number) * (uint32_t)(number - 1);
        }
    }
    size_t answer = 1;
    for (size_t number = 1; number <= limit; ++number) {
        if ((uint64_t)number * phi[answer] > (uint64_t)answer * phi[number]) answer = number;
    }
    free(phi);
    return (int64_t)answer;
}
