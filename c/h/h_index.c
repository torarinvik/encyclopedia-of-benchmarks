/* Find the greatest h for which at least h citations are >= h. */
#include <stddef.h>
#include <stdint.h>

int64_t h_index(const int64_t *citations, size_t length)
{
    if (length > 5000) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (citations[index] < 0 || citations[index] > 1000) return -1;
    }

    size_t low = 0;
    size_t high = length < 1000 ? length : 1000;
    while (low < high) {
        const size_t middle = low + (high - low + 1) / 2;
        size_t qualifying = 0;
        for (size_t index = 0; index < length; ++index) {
            if ((uint64_t)citations[index] >= middle && ++qualifying >= middle) break;
        }
        if (qualifying >= middle) low = middle;
        else high = middle - 1;
    }
    return (int64_t)low;
}
