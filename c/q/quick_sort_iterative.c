/* Iterative Lomuto quicksort using the final value as the pivot. */
#include <limits.h>
#include <stddef.h>
#include <stdint.h>

static size_t quick_sort_iterative_partition(int64_t *values, size_t low, size_t high)
{
    const int64_t pivot = values[high - 1];
    size_t boundary = low;
    for (size_t scan = low; scan < high - 1; ++scan) {
        if (values[scan] <= pivot) {
            const int64_t temporary = values[boundary];
            values[boundary] = values[scan];
            values[scan] = temporary;
            ++boundary;
        }
    }
    const int64_t temporary = values[boundary];
    values[boundary] = values[high - 1];
    values[high - 1] = temporary;
    return boundary;
}

void quick_sort_iterative(int64_t *values, size_t length)
{
    if (length < 2) return;

    enum { RANGE_STACK_CAPACITY = sizeof(size_t) * CHAR_BIT };
    size_t stack_low[RANGE_STACK_CAPACITY];
    size_t stack_high[RANGE_STACK_CAPACITY];
    size_t stack_size = 0;
    size_t low = 0;
    size_t high = length;

    for (;;) {
        while (high - low > 1) {
            const size_t pivot = quick_sort_iterative_partition(values, low, high);
            const size_t left_size = pivot - low;
            const size_t right_size = high - pivot - 1;
            if (left_size < right_size) {
                if (right_size > 1) {
                    stack_low[stack_size] = pivot + 1;
                    stack_high[stack_size] = high;
                    ++stack_size;
                }
                high = pivot;
            } else {
                if (left_size > 1) {
                    stack_low[stack_size] = low;
                    stack_high[stack_size] = pivot;
                    ++stack_size;
                }
                low = pivot + 1;
            }
        }
        if (stack_size == 0) break;
        --stack_size;
        low = stack_low[stack_size];
        high = stack_high[stack_size];
    }
}
