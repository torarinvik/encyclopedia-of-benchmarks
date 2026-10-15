#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_N 8192
#define MAP_CAPACITY 16384
#define MAP_MASK (MAP_CAPACITY - 1)

int64_t maximum_sum_of_distinct_subarrays_with_length_k(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_N + 2) return INVALID_RESULT;
    const int64_t n_value = values[0], k_value = values[1];
    if (n_value < 1 || n_value > MAX_N || k_value < 1 || k_value > n_value ||
        length != (size_t)n_value + 2) return INVALID_RESULT;
    const size_t n = (size_t)n_value, k = (size_t)k_value;
    int32_t keys[MAP_CAPACITY];
    int32_t last_plus_one[MAP_CAPACITY] = {0};
    int64_t current_sum = 0, maximum_sum = 0;
    size_t distinct_start = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t input = values[i + 2];
        if (input < INT32_MIN || input > INT32_MAX) return INVALID_RESULT;
        const int32_t value = (int32_t)input;
        if (i < k) current_sum += value;
        else {
            current_sum -= values[i - k + 2];
            current_sum += value;
        }
        size_t slot = (size_t)((input + 2147483648LL) % MAP_CAPACITY);
        while (last_plus_one[slot] != 0 && keys[slot] != value) slot = (slot + 1) & MAP_MASK;
        if (last_plus_one[slot] != 0) {
            const size_t previous = (size_t)(last_plus_one[slot] - 1);
            if (previous >= distinct_start) distinct_start = previous + 1;
        } else {
            keys[slot] = value;
        }
        last_plus_one[slot] = (int32_t)i + 1;
        if (i + 1 >= k) {
            const size_t start = i + 1 - k;
            if (start >= distinct_start && current_sum > maximum_sum) maximum_sum = current_sum;
        }
    }
    return maximum_sum;
}
