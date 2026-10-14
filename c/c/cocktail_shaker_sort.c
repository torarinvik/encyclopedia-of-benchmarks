/* Stable full-range bidirectional adjacent-swap sort. */
#include <stddef.h>
#include <stdint.h>

void cocktail_shaker_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    for (;;) {
        int swapped = 0;
        for (size_t index = 0; index + 1 < length; ++index) {
            if (values[index] > values[index + 1]) {
                const int64_t temporary = values[index];
                values[index] = values[index + 1];
                values[index + 1] = temporary;
                swapped = 1;
            }
        }
        if (!swapped) break;
        swapped = 0;
        size_t index = length - 1;
        while (index > 0) {
            if (values[index - 1] > values[index]) {
                const int64_t temporary = values[index - 1];
                values[index - 1] = values[index];
                values[index] = temporary;
                swapped = 1;
            }
            --index;
        }
        if (!swapped) break;
    }
}
