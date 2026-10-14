/*
 * Algorithm reference: TheAlgorithms/C searching/linear_search.c
 * This portable implementation follows the local benchmark contract and was
 * written independently of the upstream source.
 */
#include <stddef.h>
#include <stdint.h>

int64_t linear_search(const int64_t *values, size_t length, int64_t target)
{
    for (size_t index = 0; index < length; ++index) {
        if (values[index] == target) {
            return (int64_t)index;
        }
    }

    return -1;
}
