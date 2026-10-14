/* Portable pigeonhole sort for signed keys in [-128, 128]. */
#include <stddef.h>
#include <stdint.h>

void pigeonhole_sort(int64_t *values, int64_t *scratch, size_t length)
{
    if (length < 2) return;
    for (size_t bucket = 0; bucket < 257; ++bucket) scratch[bucket] = 0;
    for (size_t index = 0; index < length; ++index) {
        const size_t bucket = (size_t)(values[index] + 128);
        ++scratch[bucket];
    }
    size_t index = 0;
    for (size_t bucket = 0; bucket < 257; ++bucket) {
        while (scratch[bucket] > 0) {
            values[index++] = (int64_t)bucket - 128;
            --scratch[bucket];
        }
    }
}
