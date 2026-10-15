/* Maximum sum of a fixed-size window; the final packed value is k. */
#include <stddef.h>
#include <stdint.h>

int64_t max_sum_ksize_subarray(const int64_t *values, size_t length)
{
    if (length == 0 || length > 64 || values == NULL) return -1;
    const size_t array_length = length - 1;
    const int64_t k_value = values[length - 1];
    if (k_value < 0 || (uint64_t)k_value > array_length) return -1;
    for (size_t index = 0; index < array_length; ++index)
        if (values[index] < -1000000 || values[index] > 1000000) return -1;
    if (k_value == 0) return 0;

    const size_t k = (size_t)k_value;
    int64_t window_sum = 0;
    for (size_t index = 0; index < k; ++index) window_sum += values[index];
    int64_t maximum_sum = window_sum;
    for (size_t index = k; index < array_length; ++index) {
        window_sum += values[index] - values[index - k];
        if (window_sum > maximum_sum) maximum_sum = window_sum;
    }
    return maximum_sum;
}
