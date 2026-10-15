/* Encrypt 7-bit ASCII with a repeating decimal-digit Gronsfeld key. */
#include <stddef.h>
#include <stdint.h>

int64_t gronsfeld_cipher(const int64_t *input, size_t length, uint8_t *output,
                         size_t output_capacity)
{
    if (length < 1 || length > 321) return -1;
    size_t separator = 0;
    while (separator < length && input[separator] != 0) ++separator;
    if (separator == length) return -1;
    const size_t text_length = separator;
    const size_t key_length = length - separator - 1;
    if (text_length > 256 || key_length > 64) return -1;

    for (size_t index = 0; index < text_length; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    for (size_t index = 0; index < key_length; ++index) {
        const int64_t value = input[separator + 1 + index];
        if (value < 48 || value > 57) return -1;
    }
    if (key_length == 0) {
        for (size_t index = 0; index < text_length; ++index) {
            const int64_t value = input[index];
            if ((value >= 65 && value <= 90) || (value >= 97 && value <= 122)) return -1;
        }
    }
    if (output_capacity < text_length) return -2;

    for (size_t index = 0; index < text_length; ++index) {
        const int64_t value = input[index];
        int64_t mapped = value;
        if (value >= 65 && value <= 90) {
            const int64_t shift = input[separator + 1 + index % key_length] - 48;
            mapped = 65 + (value - 65 + shift) % 26;
        } else if (value >= 97 && value <= 122) {
            const int64_t shift = input[separator + 1 + index % key_length] - 48;
            mapped = 65 + (value - 97 + shift) % 26;
        }
        output[index] = (uint8_t)mapped;
    }
    return (int64_t)text_length;
}
