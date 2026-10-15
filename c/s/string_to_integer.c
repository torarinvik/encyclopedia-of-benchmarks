/* Parse an ASCII byte sequence like C atoi, clamping to signed 32-bit bounds. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 4096
#define INT32_MAX_VALUE INT64_C(2147483647)
#define INT32_MIN_MAGNITUDE INT64_C(2147483648)

int64_t string_to_integer(const int64_t *input, size_t length)
{
    if (length > MAX_INPUT_LENGTH || (length != 0 && input == NULL)) return -2;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127) return -2;

    size_t index = 0;
    while (index < length && input[index] == ' ') ++index;
    int negative = 0;
    if (index < length && (input[index] == '+' || input[index] == '-')) {
        negative = input[index] == '-';
        ++index;
    }
    const int64_t limit = negative ? INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
    int64_t magnitude = 0;
    while (index < length && input[index] >= '0' && input[index] <= '9') {
        const int64_t digit = input[index] - '0';
        if (magnitude > limit / 10 ||
            (magnitude == limit / 10 && digit > limit % 10)) {
            return negative ? -INT32_MIN_MAGNITUDE : INT32_MAX_VALUE;
        }
        magnitude = magnitude * 10 + digit;
        ++index;
    }
    return negative ? -magnitude : magnitude;
}
