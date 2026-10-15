/* Add two most-significant-first binary digit arrays. */
#include <stddef.h>
#include <stdint.h>

int64_t binary_addition(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2) return -1;

    const int64_t length_a_value = values[0];
    const int64_t length_b_value = values[1];
    if (length_a_value < 0 || length_a_value > 2047 ||
        length_b_value < 0 || length_b_value > 2047) return -1;

    const size_t length_a = (size_t)length_a_value;
    const size_t length_b = (size_t)length_b_value;
    if (length != 2 + length_a + length_b) return -1;

    for (size_t index = 0; index < length_a + length_b; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 1) return -1;

    const size_t width = length_a > length_b ? length_a : length_b;
    int carry = 0;
    for (size_t offset = 0; offset < width; ++offset) {
        const int bit_a = offset < length_a
            ? (int)values[2 + length_a - 1 - offset] : 0;
        const int bit_b = offset < length_b
            ? (int)values[2 + length_a + length_b - 1 - offset] : 0;
        carry = (bit_a + bit_b + carry) >> 1;
    }
    const size_t result_length = width + (size_t)carry;
    if (result_length == 0) return 0;
    if (output == NULL || output_capacity < result_length) return -2;

    carry = 0;
    for (size_t offset = 0; offset < width; ++offset) {
        const int bit_a = offset < length_a
            ? (int)values[2 + length_a - 1 - offset] : 0;
        const int bit_b = offset < length_b
            ? (int)values[2 + length_a + length_b - 1 - offset] : 0;
        const int sum = bit_a + bit_b + carry;
        const size_t destination = result_length - 1 - offset;
        output[destination] = (uint8_t)('0' + (sum & 1));
        carry = sum >> 1;
    }
    if (carry != 0) output[0] = (uint8_t)'1';
    return (int64_t)result_length;
}
