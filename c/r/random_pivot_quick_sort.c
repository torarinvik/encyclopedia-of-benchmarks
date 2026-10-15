/* Reproducible randomized-pivot Lomuto quicksort. */
#include <limits.h>
#include <stddef.h>
#include <stdint.h>

static uint64_t random_pivot_quick_sort_next31(uint64_t *state)
{
    *state = (*state * UINT64_C(48271)) % UINT64_C(2147483647);
    return *state;
}

static uint64_t random_pivot_quick_sort_next(uint64_t *state)
{
    const uint64_t high = random_pivot_quick_sort_next31(state);
    const uint64_t low = random_pivot_quick_sort_next31(state);
    return high * UINT64_C(2147483647) + low;
}

static size_t random_pivot_quick_sort_partition(int64_t *values, size_t low, size_t high,
                                                uint64_t *state)
{
    const size_t width = high - low;
    const size_t pivot_index = low + (size_t)(random_pivot_quick_sort_next(state) % width);
    const int64_t pivot_value = values[pivot_index];
    const int64_t pivot_slot = values[high - 1];
    values[high - 1] = pivot_value;
    values[pivot_index] = pivot_slot;

    size_t boundary = low;
    for (size_t scan = low; scan < high - 1; ++scan) {
        if (values[scan] < pivot_value) {
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

void random_pivot_quick_sort(int64_t *values, size_t length)
{
    if (length < 2) return;

    enum { RANGE_STACK_CAPACITY = sizeof(size_t) * CHAR_BIT };
    size_t stack_low[RANGE_STACK_CAPACITY];
    size_t stack_high[RANGE_STACK_CAPACITY];
    size_t stack_size = 0;
    size_t low = 0;
    size_t high = length;
    uint64_t random_state = UINT64_C(1);

    for (;;) {
        while (high - low > 1) {
            const size_t pivot = random_pivot_quick_sort_partition(values, low, high, &random_state);
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
