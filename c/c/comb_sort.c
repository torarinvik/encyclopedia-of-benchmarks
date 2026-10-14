/* Independent portable implementation of TheAlgorithms/C++ comb sort. */
#include <stddef.h>
#include <stdint.h>

static size_t shrink_gap(size_t gap)
{
    return (gap / 13) * 10 + ((gap % 13) * 10) / 13;
}

void comb_sort(int64_t *values, size_t length)
{
    if (length < 2) return;

    size_t gap = length;
    int swapped = 1;
    while (gap > 1 || swapped) {
        gap = shrink_gap(gap);
        if (gap < 1) gap = 1;
        swapped = 0;
        for (size_t index = 0; index < length - gap; ++index) {
            if (values[index] > values[index + gap]) {
                const int64_t temporary = values[index];
                values[index] = values[index + gap];
                values[index + gap] = temporary;
                swapped = 1;
            }
        }
    }
}
