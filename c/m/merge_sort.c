/* Stable bottom-up merge sort using caller-provided scratch storage. */
#include <stddef.h>
#include <stdint.h>

void merge_sort(int64_t *values, int64_t *scratch, size_t length)
{
    for (size_t width = 1; width < length;) {
        size_t low = 0;
        while (low < length) {
            size_t middle = low + width;
            if (middle > length) middle = length;
            size_t high = middle + width;
            if (high > length) high = length;
            size_t left = low;
            size_t right = middle;
            size_t output = low;
            while (left < middle && right < high) {
                if (values[left] <= values[right]) scratch[output++] = values[left++];
                else scratch[output++] = values[right++];
            }
            while (left < middle) scratch[output++] = values[left++];
            while (right < high) scratch[output++] = values[right++];
            for (size_t index = low; index < high; ++index) values[index] = scratch[index];
            low = high;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}
