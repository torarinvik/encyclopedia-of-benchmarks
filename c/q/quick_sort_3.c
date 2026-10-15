/* Portable three-way quicksort using the final value as pivot. */
#include <stddef.h>
#include <stdint.h>

static void quick_sort_3_range(int64_t *values, size_t low_value, size_t high_value)
{
    size_t low = low_value;
    size_t high = high_value;
    while (high - low > 1) {
        const int64_t pivot = values[high - 1];
        size_t less = low;
        size_t scan = low;
        size_t greater = high;
        while (scan < greater) {
            if (values[scan] < pivot) {
                const int64_t temporary = values[less];
                values[less] = values[scan];
                values[scan] = temporary;
                ++less;
                ++scan;
            } else if (values[scan] > pivot) {
                --greater;
                const int64_t temporary = values[scan];
                values[scan] = values[greater];
                values[greater] = temporary;
            } else {
                ++scan;
            }
        }
        if (less - low < high - greater) {
            quick_sort_3_range(values, low, less);
            low = greater;
        } else {
            quick_sort_3_range(values, greater, high);
            high = less;
        }
    }
}

void quick_sort_3(int64_t *values, size_t length)
{
    if (length > 1) quick_sort_3_range(values, 0, length);
}
