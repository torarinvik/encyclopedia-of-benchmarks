/* Divide-and-conquer maximum nonempty contiguous-subarray sum. */
#include <stddef.h>
#include <stdint.h>

static int64_t max_subarray_range(const int64_t *values, size_t start, size_t end)
{
    if (end - start == 1) return values[start];
    const size_t middle = start + (end - start) / 2;
    const int64_t left_best = max_subarray_range(values, start, middle);
    const int64_t right_best = max_subarray_range(values, middle, end);
    int64_t running = values[middle - 1];
    int64_t left_suffix = running;
    for (size_t index = middle - 1; index > start;) {
        --index;
        running += values[index];
        if (running > left_suffix) left_suffix = running;
    }
    running = values[middle];
    int64_t right_prefix = running;
    for (size_t index = middle + 1; index < end; ++index) {
        running += values[index];
        if (running > right_prefix) right_prefix = running;
    }
    const int64_t crossing = left_suffix + right_prefix;
    int64_t best = left_best > right_best ? left_best : right_best;
    return crossing > best ? crossing : best;
}

int64_t max_subarray(const int64_t *values, size_t length)
{
    if (length == 0 || length > 1024) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
    }
    return max_subarray_range(values, 0, length);
}
