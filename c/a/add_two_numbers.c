/* Add reverse-order decimal digit lists with a carry propagated per node. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIGITS 1024
#define MAX_INPUT_LENGTH (2 + 2 * MAX_DIGITS)

int64_t add_two_numbers(const int64_t *input, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_DIGITS || input[1] < 0 || input[1] > MAX_DIGITS) return -1;
    const size_t first_length = (size_t)input[0];
    const size_t second_length = (size_t)input[1];
    if (length != first_length + second_length + 2) return -1;
    for (size_t index = 0; index < first_length + second_length; ++index)
        if (input[index + 2] < 0 || input[index + 2] > 9) return -1;

    const size_t digit_count = first_length > second_length ? first_length : second_length;
    uint8_t digits[MAX_DIGITS + 1];
    size_t result_length = 0;
    int64_t carry = 0;
    for (size_t index = 0; index < digit_count || carry != 0; ++index) {
        const int64_t first = index < first_length ? input[index + 2] : 0;
        const int64_t second = index < second_length ? input[index + 2 + first_length] : 0;
        const int64_t sum = first + second + carry;
        digits[result_length++] = (uint8_t)(sum % 10);
        carry = sum / 10;
    }
    if (output_capacity < result_length || (result_length != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < result_length; ++index) output[index] = digits[index];
    return (int64_t)result_length;
}
