#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 15
#define MAX_STATES (1U << MAX_DIMENSION)

static int bit_count(unsigned value)
{
    int count = 0;
    while (value != 0) { count += (int)(value & 1U); value >>= 1; }
    return count;
}

int64_t problem345(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_DIMENSION * MAX_DIMENSION + 1) return -1;
    const int64_t dimension = input[0];
    if (dimension < 1 || dimension > MAX_DIMENSION
        || length != (size_t)(dimension * dimension) + 1) return -1;
    for (size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] > 1000) return -1;

    int64_t best[MAX_STATES];
    for (unsigned mask = 0; mask < MAX_STATES; ++mask) best[mask] = -1;
    best[0] = 0;
    const unsigned state_count = 1U << (unsigned)dimension;
    for (unsigned mask = 0; mask < state_count; ++mask) {
        if (best[mask] < 0) continue;
        const int row = bit_count(mask);
        if (row >= dimension) continue;
        for (int column = 0; column < dimension; ++column) {
            const unsigned bit = 1U << (unsigned)column;
            if ((mask & bit) != 0) continue;
            const unsigned next = mask | bit;
            const int64_t candidate = best[mask] + input[1 + (size_t)row * (size_t)dimension + (size_t)column];
            if (candidate > best[next]) best[next] = candidate;
        }
    }
    return best[state_count - 1];
}
