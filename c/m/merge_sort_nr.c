#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

void merge_sort_nr(int64_t *values, size_t length)
{
    if (length > MAX_VALUES) {
        return;
    }

    int64_t scratch[MAX_VALUES];
    for (size_t width = 1; width < length; width *= 2) {
        for (size_t start = 0; start < length; start += width * 2) {
            size_t middle = start + width;
            if (middle > length) {
                middle = length;
            }
            size_t end = middle + width;
            if (end > length) {
                end = length;
            }

            size_t left = start;
            size_t right = middle;
            size_t output = start;
            while (left < middle && right < end) {
                scratch[output++] = values[left] <= values[right]
                    ? values[left++] : values[right++];
            }
            while (left < middle) {
                scratch[output++] = values[left++];
            }
            while (right < end) {
                scratch[output++] = values[right++];
            }
        }
        for (size_t index = 0; index < length; ++index) {
            values[index] = scratch[index];
        }
    }
}
