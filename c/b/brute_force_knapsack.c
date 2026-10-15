#include <stddef.h>
#include <stdint.h>

static int64_t solve(const int64_t *packed, size_t item_count, int64_t capacity)
{
    if (item_count == 0 || capacity == 0) return 0;
    const int64_t weight = packed[2 + 2 * (item_count - 1)];
    const int64_t value = packed[3 + 2 * (item_count - 1)];
    if (weight > capacity) return solve(packed, item_count - 1, capacity);
    const int64_t excluded = solve(packed, item_count - 1, capacity);
    const int64_t included = value + solve(packed, item_count - 1, capacity - weight);
    return excluded > included ? excluded : included;
}

int64_t brute_force_knapsack(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 30) return -1;
    const int64_t capacity = packed[0];
    const int64_t count_value = packed[1];
    if (capacity < 0 || capacity > 512 || count_value < 0 || count_value > 14) return -1;
    const size_t item_count = (size_t)count_value;
    if (length != 2 + 2 * item_count) return -1;
    for (size_t item = 0; item < item_count; ++item) {
        const int64_t weight = packed[2 + 2 * item];
        const int64_t value = packed[3 + 2 * item];
        if (weight < 1 || weight > 4096 || value < 0 || value > 100000000) return -1;
    }
    return solve(packed, item_count, capacity);
}
