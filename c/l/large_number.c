#include <stddef.h>
#include <stdint.h>

#define MAX_DIGITS 64u
#define MAX_INPUT_LENGTH (2u + 2u * MAX_DIGITS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_LENGTH + 1u)
#define MAX_OUTPUT_BYTES (MAX_DIGITS + 1u)

static int is_decimal_digit(int64_t value)
{
    return value >= 48 && value <= 57;
}

int64_t large_number_add(const int64_t *input, size_t input_length,
                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2u ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    const int64_t left_length_value = input[0];
    const int64_t right_length_value = input[1];
    if (left_length_value < 1 || left_length_value > (int64_t)MAX_DIGITS ||
        right_length_value < 1 || right_length_value > (int64_t)MAX_DIGITS) return -1;

    const size_t left_length = (size_t)left_length_value;
    const size_t right_length = (size_t)right_length_value;
    if (input_length != 2u + left_length + right_length) return -1;

    const size_t left_start = 2u;
    const size_t right_start = left_start + left_length;
    for (size_t i = 0u; i < left_length; ++i) {
        if (!is_decimal_digit(input[left_start + i])) return -1;
    }
    for (size_t i = 0u; i < right_length; ++i) {
        if (!is_decimal_digit(input[right_start + i])) return -1;
    }
    if ((left_length > 1u && input[left_start] == 48) ||
        (right_length > 1u && input[right_start] == 48)) return -1;

    uint8_t reversed[MAX_OUTPUT_BYTES];
    size_t result_length = 0u;
    size_t index = 0u;
    const size_t max_length = left_length > right_length ? left_length : right_length;
    int64_t carry = 0;
    while (index < max_length || carry != 0) {
        int64_t total = carry;
        if (index < right_length) {
            total += input[right_start + right_length - index - 1u] - 48;
        }
        if (index < left_length) {
            total += input[left_start + left_length - index - 1u] - 48;
        }
        reversed[result_length++] = (uint8_t)(48 + total % 10);
        carry = total / 10;
        ++index;
    }

    uint8_t result[MAX_OUTPUT_BYTES];
    for (size_t i = 0u; i < result_length; ++i) {
        result[i] = reversed[result_length - i - 1u];
    }

    if (output == NULL || output_capacity < result_length) return -2;
    for (size_t i = 0u; i < result_length; ++i) output[i] = result[i];
    return (int64_t)result_length;
}
