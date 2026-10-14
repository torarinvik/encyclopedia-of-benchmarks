/* Stable bottom-up TimSort-style merge sort with reusable caller scratch. */
#include <stddef.h>
#include <stdint.h>

enum { TIM_SORT_RUN = 32 };

static void insertion_sort_run(int64_t *values, size_t low, size_t high)
{
    for (size_t index = low + 1; index < high; ++index) {
        const int64_t key = values[index];
        size_t cursor = index;
        while (cursor > low && values[cursor - 1] > key) {
            values[cursor] = values[cursor - 1];
            --cursor;
        }
        values[cursor] = key;
    }
}

static void merge_runs(int64_t *values, int64_t *scratch,
                       size_t left, size_t middle, size_t right)
{
    for (size_t index = left; index < right; ++index) scratch[index] = values[index];
    size_t first = left;
    size_t second = middle;
    for (size_t output = left; output < right; ++output) {
        if (first == middle) {
            values[output] = scratch[second++];
        } else if (second == right || scratch[first] <= scratch[second]) {
            values[output] = scratch[first++];
        } else {
            values[output] = scratch[second++];
        }
    }
}

void tim_sort(int64_t *values, int64_t *scratch, size_t length)
{
    if (length < 2) return;
    size_t start = 0;
    while (start < length) {
        const size_t remaining = length - start;
        const size_t end = remaining < TIM_SORT_RUN ? length : start + TIM_SORT_RUN;
        insertion_sort_run(values, start, end);
        start = end;
    }

    size_t width = TIM_SORT_RUN;
    while (width < length) {
        size_t left = 0;
        while (left < length) {
            const size_t middle = left + (width < length - left ? width : length - left);
            const size_t right = middle + (width < length - middle ? width : length - middle);
            if (middle < right) merge_runs(values, scratch, left, middle, right);
            left = right;
        }
        if (width >= length - width) break;
        width *= 2;
    }
}
