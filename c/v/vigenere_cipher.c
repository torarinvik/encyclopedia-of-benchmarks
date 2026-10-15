/* Encrypt ASCII text with a repeating, case-insensitive Vigenere key. */
#include <stddef.h>
#include <stdint.h>

int64_t vigenere_cipher(const int64_t *input, size_t length, uint8_t *output,
                        size_t output_capacity)
{
    if (length < 2 || length > 66) return -1;
    size_t separator = 0;
    while (separator < length && input[separator] != 0) ++separator;
    if (separator == length || separator + 1 == length) return -1;
    const size_t key_length = length - separator - 1;
    for (size_t index = 0; index < separator; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    for (size_t index = 0; index < key_length; ++index) {
        const int64_t value = input[separator + 1 + index];
        if (!((value >= 65 && value <= 90) || (value >= 97 && value <= 122))) return -1;
    }
    if (output_capacity < separator) return -2;

    size_t key_index = 0;
    for (size_t index = 0; index < separator; ++index) {
        const int64_t value = input[index];
        int64_t mapped = value;
        if (value >= 65 && value <= 90) {
            int64_t key_value = input[separator + 1 + key_index];
            if (key_value >= 97) key_value -= 32;
            mapped = 65 + (value - 65 + key_value - 65) % 26;
            key_index = (key_index + 1) % key_length;
        } else if (value >= 97 && value <= 122) {
            int64_t key_value = input[separator + 1 + key_index];
            if (key_value <= 90) key_value += 32;
            mapped = 97 + (value - 97 + key_value - 97) % 26;
            key_index = (key_index + 1) % key_length;
        }
        output[index] = (uint8_t)mapped;
    }
    return (int64_t)separator;
}
