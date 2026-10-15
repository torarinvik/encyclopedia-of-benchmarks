#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_N 100000

int64_t max_sum_sliding_window(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_N + 2) return INVALID_RESULT;
    const int64_t n_value = values[0], k_value = values[1];
    if (n_value < 1 || n_value > MAX_N || k_value < 1 || k_value > n_value ||
        length != (size_t)n_value + 2) return INVALID_RESULT;
    const size_t n = (size_t)n_value, k = (size_t)k_value;
    int64_t current_sum = 0;
    for (size_t i = 0; i < n; ++i) {
        if (values[i + 2] < -1000000000 || values[i + 2] > 1000000000) return INVALID_RESULT;
        if (i < k) current_sum += values[i + 2];
    }
    int64_t maximum_sum = current_sum;
    for (size_t i = 0; i < n - k; ++i) {
        current_sum = current_sum - values[i + 2] + values[i + k + 2];
        if (current_sum > maximum_sum) maximum_sum = current_sum;
    }
    return maximum_sum;
}
