/* Reciprocal Porta tableau cipher. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PORTA_TEXT_LENGTH 1024
#define MAX_PORTA_KEY_LENGTH 64

int64_t porta_cipher(const int64_t *input, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > 3 + MAX_PORTA_TEXT_LENGTH + MAX_PORTA_KEY_LENGTH) return -1;
    const int64_t mode = input[0], text_value = input[1], key_value = input[2];
    if ((mode != 0 && mode != 1) || text_value < 0 || text_value > MAX_PORTA_TEXT_LENGTH
        || key_value < 0 || key_value > MAX_PORTA_KEY_LENGTH) return -1;
    const size_t text_length = (size_t)text_value, key_length = (size_t)key_value;
    if (length != 3 + text_length + key_length || (text_length != 0 && key_length == 0)) return -1;
    const size_t key_start = 3 + text_length;
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = input[3 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    for (size_t i = 0; i < key_length; ++i) {
        const int64_t value = input[key_start + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    if (output_capacity < text_length || (text_length != 0 && output == NULL)) return -2;
    for (size_t i = 0; i < text_length; ++i) {
        int64_t letter = input[3 + i];
        int64_t key_letter = input[key_start + i % key_length];
        if (letter >= 'a') letter -= 32;
        if (key_letter >= 'a') key_letter -= 32;
        const int64_t letter_index = letter - 'A';
        const int64_t group = (key_letter - 'A') / 2;
        const int64_t mapped = letter_index < 13
            ? 13 + (letter_index + 13 - group) % 13
            : (letter_index - 13 + group) % 13;
        output[i] = (uint8_t)('A' + mapped);
    }
    return (int64_t)text_length;
}
