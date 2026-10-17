#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 256
#define INT32_MAX_VALUE INT64_C(2147483647)
#define INT32_MIN_MAGNITUDE INT64_C(2147483648)

int64_t my_atoi(const int64_t *input, size_t length) {
    if (input == NULL) return 0;
    if (length > MAX_INPUT_LENGTH) return INT64_MIN;
    for (size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127) return INT64_MIN;

    size_t start = 0, end = length;
    while (start < end && input[start] <= 0x20) ++start;
    while (end > start && input[end - 1] <= 0x20) --end;
    if (start == end) return 0;

    int negative = 0;
    if (input[start] == '+' || input[start] == '-') {
        negative = input[start] == '-';
        ++start;
    }
    const int64_t limit = negative ? INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
    int64_t magnitude = 0;
    while (start < end && input[start] >= '0' && input[start] <= '9') {
        const int64_t digit = input[start] - '0';
        if (magnitude > limit / 10 || (magnitude == limit / 10 && digit > limit % 10))
            return negative ? -INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
        magnitude = magnitude * 10 + digit;
        ++start;
    }
    return negative ? -magnitude : magnitude;
}
