/* Portable dual-pivot quicksort using the first and final values as pivots. */
#include <stddef.h>
#include <stdint.h>

static void dual_pivot_sort_range(int64_t *values, size_t low_value, size_t high_value)
{
    size_t low = low_value;
    size_t high = high_value;
    while (high - low > 2) {
        if (values[low] > values[high - 1]) {
            const int64_t temporary = values[low];
            values[low] = values[high - 1];
            values[high - 1] = temporary;
        }
        const int64_t pivot1 = values[low];
        const int64_t pivot2 = values[high - 1];
        size_t less = low + 1;
        size_t scan = low + 1;
        size_t greater = high - 2;
        while (scan <= greater) {
            if (values[scan] < pivot1) {
                const int64_t temporary = values[scan];
                values[scan] = values[less];
                values[less] = temporary;
                ++less;
            } else if (values[scan] >= pivot2) {
                while (scan < greater && values[greater] > pivot2) --greater;
                const int64_t temporary = values[scan];
                values[scan] = values[greater];
                values[greater] = temporary;
                --greater;
                if (values[scan] < pivot1) {
                    const int64_t second_temporary = values[scan];
                    values[scan] = values[less];
                    values[less] = second_temporary;
                    ++less;
                }
            }
            ++scan;
        }
        const size_t pivot1_index = less - 1;
        const size_t pivot2_index = greater + 1;
        const int64_t first_temporary = values[low];
        values[low] = values[pivot1_index];
        values[pivot1_index] = first_temporary;
        const int64_t second_temporary = values[high - 1];
        values[high - 1] = values[pivot2_index];
        values[pivot2_index] = second_temporary;

        const size_t left_size = pivot1_index - low;
        const size_t middle_size = pivot2_index - pivot1_index - 1;
        const size_t right_size = high - pivot2_index - 1;
        if (left_size >= middle_size && left_size >= right_size) {
            dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index);
            dual_pivot_sort_range(values, pivot2_index + 1, high);
            high = pivot1_index;
        } else if (middle_size >= right_size) {
            dual_pivot_sort_range(values, low, pivot1_index);
            dual_pivot_sort_range(values, pivot2_index + 1, high);
            low = pivot1_index + 1;
            high = pivot2_index;
        } else {
            dual_pivot_sort_range(values, low, pivot1_index);
            dual_pivot_sort_range(values, pivot1_index + 1, pivot2_index);
            low = pivot2_index + 1;
        }
    }
    if (high - low == 2 && values[low] > values[low + 1]) {
        const int64_t temporary = values[low];
        values[low] = values[low + 1];
        values[low + 1] = temporary;
    }
}

void dual_pivot_quick_sort(int64_t *values, size_t length)
{
    if (length > 1) dual_pivot_sort_range(values, 0, length);
}
