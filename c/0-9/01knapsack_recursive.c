#include <stddef.h>
#include <stdint.h>

enum { MAX_CAPACITY = 512, MAX_ITEMS = 16, MAX_WEIGHT = 4096 };
static const int64_t MAX_VALUE = 1000000000;

static int64_t solve(const int64_t *packed, int64_t item_count, int64_t capacity)
{
    if (item_count == 0 || capacity == 0) return 0;
    const size_t offset = 2 + 2 * (size_t)(item_count - 1);
    const int64_t weight = packed[offset];
    const int64_t value = packed[offset + 1];
    if (weight <= capacity) {
        const int64_t take = value + solve(packed, item_count - 1, capacity - weight);
        const int64_t skip = solve(packed, item_count - 1, capacity);
        return take > skip ? take : skip;
    }
    return solve(packed, item_count - 1, capacity);
}

int64_t knapsack_01_recursive_benchmark(const int64_t *packed, size_t length)
{
    if (length < 2 || length > 2 + 2 * MAX_ITEMS) return -1;
    const int64_t capacity = packed[0];
    const int64_t item_count = packed[1];
    if (capacity < 0 || capacity > MAX_CAPACITY || item_count < 0 || item_count > MAX_ITEMS
        || length != 2 + 2 * (size_t)item_count) return -1;
    for (int64_t item = 0; item < item_count; ++item) {
        const size_t offset = 2 + 2 * (size_t)item;
        if (packed[offset] < 1 || packed[offset] > MAX_WEIGHT
            || packed[offset + 1] < 0 || packed[offset + 1] > MAX_VALUE) return -1;
    }
    return solve(packed, item_count, capacity);
}
