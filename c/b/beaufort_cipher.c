/* Preserve the pinned Python source's plaintext-minus-repeating-key transform. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BEAUFORT_LENGTH 1024

int64_t beaufort_cipher(const int64_t *input, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > 3 + 2 * MAX_BEAUFORT_LENGTH) return -1;
    const int64_t mode = input[0], text_length_value = input[1], key_length_value = input[2];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > MAX_BEAUFORT_LENGTH
        || key_length_value < 0 || key_length_value > MAX_BEAUFORT_LENGTH) return -1;
    const size_t text_length = (size_t)text_length_value, key_length = (size_t)key_length_value;
    if (length != 3 + text_length + key_length || (text_length == 0 && key_length != 0)
        || (text_length != 0 && (key_length == 0 || key_length > text_length))) return -1;
    const size_t key_start = 3 + text_length;
    for (size_t i = 0; i < text_length; ++i)
        if (input[3 + i] != ' ' && (input[3 + i] < 'A' || input[3 + i] > 'Z')) return -1;
    for (size_t i = 0; i < key_length; ++i)
        if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
    if (output_capacity < text_length || (text_length != 0 && output == NULL)) return -2;

    size_t key_index = 0;
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = input[3 + i];
        if (value == ' ') { output[i] = ' '; continue; }
        const int64_t text_value = value - 'A';
        const int64_t key_value = input[key_start + key_index % key_length] - 'A';
        const int64_t mapped = mode == 0 ? (text_value - key_value + 26) % 26
                                         : (text_value + key_value) % 26;
        output[i] = (uint8_t)('A' + mapped);
        ++key_index;
    }
    return (int64_t)text_length;
}
