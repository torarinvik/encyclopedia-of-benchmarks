#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-INT64_C(1))
#define MAX_ARRAY_LENGTH 256
#define MAX_INPUT_LENGTH (MAX_ARRAY_LENGTH + 3)
#define MAX_DOMAIN_VALUE INT64_C(2147483647)
int64_t longest_subarray_with_sum_at_most(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t target = input[0], raw_count = input[1];
    if (target < 0 || target > MAX_DOMAIN_VALUE || raw_count < 0 || raw_count > MAX_ARRAY_LENGTH) return INVALID_RESULT;
    const size_t count = (size_t)raw_count;
    if (length != count + 2) return INVALID_RESULT;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[index + 2];
        if (value < 0 || value > MAX_DOMAIN_VALUE) return INVALID_RESULT;
    }
    size_t left = 0, best_length = 0;
    int64_t window_sum = 0;
    for (size_t right = 0; right < count; ++right) {
        window_sum += input[right + 2];
        while (window_sum > target && left <= right) {
            window_sum -= input[left + 2];
            ++left;
        }
        const size_t current_length = left <= right ? right - left + 1 : 0;
        if (current_length > best_length) best_length = current_length;
    }
    return (int64_t)best_length;
}
