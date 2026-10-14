/* Independent portable implementation of TheAlgorithms/C interpolation search. */
#include <stddef.h>
#include <stdint.h>

int64_t interpolation_search(const int64_t *values, size_t length, int64_t target)
{
    if (length == 0) return -1;
    size_t low = 0;
    size_t high = length - 1;

    while (low <= high) {
        const int64_t low_value = values[low];
        const int64_t high_value = values[high];
        if (target < low_value || target > high_value) return -1;
        if (low_value == high_value) return low_value == target ? (int64_t)low : -1;

        const int64_t numerator = (target - low_value) * (int64_t)(high - low);
        const int64_t denominator = high_value - low_value;
        const size_t position = low + (size_t)(numerator / denominator);
        const int64_t value = values[position];
        if (value == target) return (int64_t)position;
        if (value < target) {
            low = position + 1;
        } else {
            if (position == 0) return -1;
            high = position - 1;
        }
    }
    return -1;
}
