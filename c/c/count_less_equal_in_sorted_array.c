#include <stddef.h>
#include <stdint.h>

int64_t count_less_equal_in_sorted_array(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 513) return -1;
    const int64_t key = input[0];
    if (key < INT32_MIN || key > INT32_MAX) return -1;
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = input[index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (index > 1 && input[index - 1] > value) return -1;
    }

    int64_t left = 1;
    int64_t right = (int64_t)length - 1;
    int64_t count = 0;
    while (left <= right) {
        const int64_t middle = left + (right - left) / 2;
        if (input[middle] > key) right = middle - 1;
        else {
            count = middle;
            left = middle + 1;
        }
    }
    return count;
}
