/* Descending Lomuto quickselect with the final element as pivot. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 512

int64_t kth_largest_element(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_LENGTH + 1) return -1;
    const size_t count = length - 1;
    if (input[0] < 1 || input[0] > (int64_t)count) return -1;
    int32_t values[MAX_LENGTH];
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 1];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        values[index] = (int32_t)value;
    }

    const size_t target = (size_t)input[0] - 1;
    size_t low = 0, high = count - 1;
    while (low <= high) {
        const int32_t pivot = values[high];
        size_t boundary = low;
        for (size_t scan = low; scan < high; ++scan) {
            if (values[scan] >= pivot) {
                const int32_t temporary = values[boundary];
                values[boundary] = values[scan];
                values[scan] = temporary;
                ++boundary;
            }
        }
        const int32_t temporary = values[boundary];
        values[boundary] = values[high];
        values[high] = temporary;
        if (boundary == target) return values[boundary];
        if (boundary > target) high = boundary - 1;
        else low = boundary + 1;
    }
    return -1;
}
