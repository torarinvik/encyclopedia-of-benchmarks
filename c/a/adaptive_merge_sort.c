#include <stddef.h>
#include <stdint.h>

#define MAX_VALUES 1024

static void adaptive_merge_sort_range(int64_t *values, int64_t *scratch,
                               size_t low, size_t high)
{
    if (high - low <= 1) return;
    const size_t middle = low + (high - low) / 2;
    adaptive_merge_sort_range(values, scratch, low, middle);
    adaptive_merge_sort_range(values, scratch, middle, high);
    if (values[middle - 1] <= values[middle]) return;

    size_t left = low;
    size_t right = middle;
    size_t output = low;
    while (left < middle && right < high) {
        scratch[output++] = values[left] <= values[right]
            ? values[left++] : values[right++];
    }
    while (left < middle) scratch[output++] = values[left++];
    while (right < high) scratch[output++] = values[right++];
    for (size_t index = low; index < high; ++index) values[index] = scratch[index];
}

void adaptive_merge_sort(int64_t *values, size_t length)
{
    if (length > MAX_VALUES) return;
    int64_t scratch[MAX_VALUES];
    adaptive_merge_sort_range(values, scratch, 0, length);
}
