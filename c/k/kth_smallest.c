/* One-based quickselect using the pinned last-element partition. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256

static size_t partition_values(int32_t *values, size_t low, size_t high)
{
    const size_t pivot = high;
    size_t i = low;
    size_t j = high - 1;
    for (;;) {
        while (values[i] < values[pivot]) ++i;
        while (j > 0 && values[j] > values[pivot]) --j;
        if (j == 0 || i >= j) break;
        if (values[i] == values[j]) {
            ++i;
            --j;
        } else {
            const int32_t temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
        }
    }
    const int32_t temporary = values[i];
    values[i] = values[pivot];
    values[pivot] = temporary;
    return i;
}

int64_t kth_smallest(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_LENGTH + 2) return INT64_MIN;
    const int64_t n_value = input[0], k_value = input[1];
    if (n_value < 1 || n_value > MAX_LENGTH || k_value < 1 || k_value > n_value ||
        length != (size_t)n_value + 2) return INT64_MIN;
    const size_t n = (size_t)n_value;
    int32_t values[MAX_LENGTH];
    for (size_t index = 0; index < n; ++index) {
        const int64_t value = input[index + 2];
        if (value < INT32_MIN || value > INT32_MAX) return INT64_MIN;
        values[index] = (int32_t)value;
    }

    size_t low = 0, high = n - 1, k = (size_t)k_value;
    while (low < high) {
        const size_t pivot = partition_values(values, low, high);
        const size_t pivot_rank = pivot - low + 1;
        if (k == pivot_rank) return values[pivot];
        if (k < pivot_rank) {
            high = pivot - 1;
        } else {
            low = pivot + 1;
            k -= pivot_rank;
        }
    }
    return values[low];
}
