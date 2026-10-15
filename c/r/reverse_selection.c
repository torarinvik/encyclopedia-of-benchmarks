/* Selection sort variant that reverses each prefix to place its minimum. */
#include <stddef.h>
#include <stdint.h>

void reverse_selection(int64_t *values, size_t length)
{
    if (length < 2) return;
    for (size_t start = 0; start + 1 < length; ++start) {
        size_t minimum = start;
        for (size_t scan = start + 1; scan < length; ++scan) {
            if (values[scan] < values[minimum]) minimum = scan;
        }
        size_t left = start;
        size_t right = minimum;
        while (left < right) {
            const int64_t temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
            ++left;
            --right;
        }
    }
}
