/* Parse an ASCII base-2 integer, add three, and format with minimum width four. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 128
#define MAX_MAGNITUDE INT64_C(4611686018427387904)

static int is_ascii_space(int64_t value)
{
    return value == 32 || (value >= 9 && value <= 13);
}

static int is_binary_digit(int64_t value)
{
    return value == '0' || value == '1';
}

int64_t binary_to_excess3(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length == 0 || length > MAX_TEXT_LENGTH) return -1;

    size_t start = 0, end = length;
    while (start < end && is_ascii_space(values[start])) ++start;
    while (end > start && is_ascii_space(values[end - 1])) --end;
    if (start == end) return -1;

    int negative = 0;
    if (values[start] == '+' || values[start] == '-') {
        negative = values[start] == '-';
        ++start;
        if (start == end) return -1;
    }

    int prefixed = end - start >= 2 && values[start] == '0' &&
                   (values[start + 1] == 'b' || values[start + 1] == 'B');
    if (prefixed) start += 2;
    if (start == end) return -1;

    const size_t digit_start = start;
    int allow_prefix_underscore = prefixed;
    int have_digit = 0, last_was_digit = 0;
    int64_t magnitude = 0;
    for (size_t index = start; index < end; ++index) {
        const int64_t value = values[index];
        if (is_binary_digit(value)) {
            const int64_t digit = value - '0';
            if (magnitude > (MAX_MAGNITUDE - digit) / 2) return -1;
            magnitude = magnitude * 2 + digit;
            have_digit = 1;
            last_was_digit = 1;
            allow_prefix_underscore = 0;
        } else if (value == '_') {
            if (last_was_digit && index + 1 < end && is_binary_digit(values[index + 1])) {
                last_was_digit = 0;
            } else if (allow_prefix_underscore && !have_digit && index == digit_start &&
                       index + 1 < end && is_binary_digit(values[index + 1])) {
                allow_prefix_underscore = 0;
            } else {
                return -1;
            }
        } else {
            return -1;
        }
    }
    if (!have_digit || !last_was_digit) return -1;

    int64_t result = negative ? -magnitude : magnitude;
    result += 3;
    const int result_is_negative = result < 0;
    int64_t remaining = result_is_negative ? -result : result;
    uint8_t reversed[64];
    size_t digit_count = 0;
    do {
        reversed[digit_count++] = (uint8_t)('0' + remaining % 2);
        remaining /= 2;
    } while (remaining > 0);

    const size_t sign_length = result_is_negative ? 1 : 0;
    size_t output_length = sign_length + digit_count;
    if (output_length < 4) output_length = 4;
    if (output == NULL || output_capacity < output_length) return -2;

    size_t position = 0;
    if (result_is_negative) output[position++] = (uint8_t)'-';
    const size_t digit_width = output_length - sign_length;
    for (size_t pad = digit_count; pad < digit_width; ++pad) output[position++] = (uint8_t)'0';
    while (digit_count > 0) output[position++] = reversed[--digit_count];
    return (int64_t)output_length;
}
