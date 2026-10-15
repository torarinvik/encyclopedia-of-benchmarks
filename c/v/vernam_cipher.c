/* Alphabetic Vernam cipher with a repeating key and modulo-26 arithmetic. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERNAM_LENGTH 1024

int64_t vernam_cipher(const int64_t *input, size_t length, uint8_t *output,
                      size_t output_capacity)
{
    if (input == NULL || length < 3 || length > 3 + 2 * MAX_VERNAM_LENGTH) return -1;
    const int64_t mode = input[0];
    const int64_t text_length_value = input[1];
    const int64_t key_length_value = input[2];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > MAX_VERNAM_LENGTH
        || key_length_value < 1 || key_length_value > MAX_VERNAM_LENGTH) return -1;
    const size_t text_length = (size_t)text_length_value;
    const size_t key_length = (size_t)key_length_value;
    if (length != 3 + text_length + key_length) return -1;
    const size_t key_start = 3 + text_length;
    for (size_t i = 0; i < text_length; ++i)
        if (input[3 + i] < 'A' || input[3 + i] > 'Z') return -1;
    for (size_t i = 0; i < key_length; ++i)
        if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
    if (output_capacity < text_length) return -2;

    for (size_t i = 0; i < text_length; ++i) {
        const int64_t text_value = input[3 + i] - 'A';
        const int64_t key_value = input[key_start + i % key_length] - 'A';
        const int64_t mapped = mode == 0 ? (text_value + key_value) % 26
                                         : (text_value - key_value + 26) % 26;
        output[i] = (uint8_t)('A' + mapped);
    }
    return (int64_t)text_length;
}
