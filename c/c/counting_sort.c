/* Counting sort for signed keys in the inclusive range [-128, 128]. */
#include <stddef.h>
#include <stdint.h>

void counting_sort(int64_t *values, int64_t *counts, size_t length)
{
    for (size_t bucket = 0; bucket < 257; ++bucket) counts[bucket] = 0;
    for (size_t index = 0; index < length; ++index) {
        const size_t bucket = (size_t)(values[index] + 128);
        ++counts[bucket];
    }
    size_t output = 0;
    for (size_t bucket = 0; bucket < 257; ++bucket) {
        while (counts[bucket] > 0) {
            values[output++] = (int64_t)bucket - 128;
            --counts[bucket];
        }
    }
}
