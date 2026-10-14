/*
 * Algorithm reference: TheAlgorithms/C searching/exponential_search.c
 * This portable implementation follows the local contract independently.
 */
#include <stddef.h>
#include <stdint.h>

static int64_t binary_search_range(const int64_t *values, size_t low, size_t high,
                                   int64_t target)
{
    while (low < high) {
        const size_t middle = low + (high - low) / 2;
        const int64_t value = values[middle];
        if (value == target) {
            return (int64_t)middle;
        }
        if (value < target) {
            low = middle + 1;
        } else {
            high = middle;
        }
    }

    return -1;
}

int64_t exponential_search(const int64_t *values, size_t length, int64_t target)
{
    if (length == 0) {
        return -1;
    }

    size_t upper = 1;
    while (upper < length && values[upper] <= target) {
        upper = upper > length / 2 ? length : upper * 2;
    }

    return binary_search_range(values, upper / 2, upper, target);
}
