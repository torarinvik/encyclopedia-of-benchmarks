/* Apply a normalized Caesar shift to ASCII letters in a byte sequence. */
#include <stddef.h>
#include <stdint.h>

int64_t caesar_cipher(const int64_t *input, size_t length, uint8_t *output,
                      size_t output_capacity)
{
    if (length == 0 || length > 66) return -1;
    const size_t text_length = length - 1;
    for (size_t index = 0; index < text_length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (output_capacity < text_length) return -2;

    int64_t shift = input[text_length] % 26;
    if (shift < 0) shift += 26;
    for (size_t index = 0; index < text_length; ++index) {
        const int64_t value = input[index];
        int64_t mapped = value;
        if (value >= 65 && value <= 90) mapped = 65 + (value - 65 + shift) % 26;
        else if (value >= 97 && value <= 122) mapped = 97 + (value - 97 + shift) % 26;
        output[index] = (uint8_t)mapped;
    }
    return (int64_t)text_length;
}
