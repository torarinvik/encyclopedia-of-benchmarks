#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MIN_N 2
#define MAX_N 10000
#define INT32_MIN_VALUE (-2147483647LL - 1)
#define INT32_MAX_VALUE 2147483647LL

int64_t find_second_largest_element(const int64_t *input, size_t length) {
    if (input == NULL || length < MIN_N + 1 || length > MAX_N + 1) return INVALID_RESULT;
    const int64_t n = input[0];
    if (n < MIN_N || n > MAX_N || length != (size_t)n + 1) return INVALID_RESULT;
    int64_t largest = INT32_MIN_VALUE;
    for (size_t i = 0; i < (size_t)n; ++i) {
        const int64_t value = input[i + 1];
        if (value < INT32_MIN_VALUE || value > INT32_MAX_VALUE) return INVALID_RESULT;
        if (value > largest) largest = value;
    }
    int64_t second = INT32_MIN_VALUE - 1;
    for (size_t i = 0; i < (size_t)n; ++i) {
        const int64_t value = input[i + 1];
        if (value < largest && value > second) second = value;
    }
    return second == INT32_MIN_VALUE - 1 ? INVALID_RESULT : second;
}
