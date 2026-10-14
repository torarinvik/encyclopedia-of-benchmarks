/* In-place cycle sort for signed 64-bit values. */
#include <stddef.h>
#include <stdint.h>

void cycle_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    for (size_t cycle_start = 0; cycle_start < length - 1; ++cycle_start) {
        int64_t item = values[cycle_start];
        size_t position = cycle_start;
        for (size_t scan = cycle_start + 1; scan < length; ++scan) {
            if (values[scan] < item) ++position;
        }
        if (position == cycle_start) continue;
        while (position < length && item == values[position]) ++position;
        if (position == length) continue;
        int64_t temporary = values[position];
        values[position] = item;
        item = temporary;
        while (position != cycle_start) {
            position = cycle_start;
            for (size_t scan = cycle_start + 1; scan < length; ++scan) {
                if (values[scan] < item) ++position;
            }
            while (position < length && item == values[position]) ++position;
            if (position == length) break;
            temporary = values[position];
            values[position] = item;
            item = temporary;
        }
    }
}
