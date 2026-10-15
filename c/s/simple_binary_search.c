/* Independent portable implementation of TheAlgorithms/Java recursive search. */
#include <stddef.h>
#include <stdint.h>

static int64_t simple_binary_search_range(const int64_t *values,
                                             size_t low,
                                             size_t high,
                                             int64_t target)
{
    if (low >= high) {
        return 0;
    }

    const size_t middle = low + (high - low) / 2;
    if (values[middle] == target) {
        return 1;
    }
    if (target < values[middle]) {
        return simple_binary_search_range(values, low, middle, target);
    }
    return simple_binary_search_range(values, middle + 1, high, target);
}

int64_t simple_binary_search(const int64_t *values, size_t length, int64_t target)
{
    return simple_binary_search_range(values, 0, length, target);
}
