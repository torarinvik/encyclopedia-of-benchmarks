/*
 * Algorithm reference: TheAlgorithms/C searching/binary_search.c
 * This portable implementation follows the local ascending-array contract and
 * was written independently of the upstream source.
 */
#include <stddef.h>
#include <stdint.h>

int64_t binary_search(const int64_t *values, size_t length, int64_t target)
{
    size_t low = 0;
    size_t high = length;

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
