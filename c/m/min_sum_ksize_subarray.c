#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_N 100000

int64_t min_sum_ksize_subarray(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_N + 2) return INVALID_RESULT;
    const int64_t n_value = values[0], k_value = values[1];
    if (n_value < 0 || n_value > MAX_N || k_value < 0 || k_value > MAX_N ||
        length != (size_t)n_value + 2) return INVALID_RESULT;
    const size_t n = (size_t)n_value, k = (size_t)k_value;
    for (size_t i = 0; i < n; ++i)
        if (values[i + 2] < -10000 || values[i + 2] > 10000) return INVALID_RESULT;
    if (k > n) return -1;
    int64_t window_sum = 0;
    for (size_t i = 0; i < k; ++i) window_sum += values[i + 2];
    int64_t minimum_sum = window_sum;
    for (size_t i = k; i < n; ++i) {
        window_sum += values[i + 2] - values[i - k + 2];
        if (window_sum < minimum_sum) minimum_sum = window_sum;
    }
    return minimum_sum;
}
