/* Plaintext-autokey cipher with a selectable output case dialect. */
#include <stddef.h>
#include <stdint.h>

#define MAX_AUTOKEY_LENGTH 1024

static int64_t uppercase_letter(int64_t value)
{
    return value >= 'a' && value <= 'z' ? value - 32 : value;
}

int64_t autokey_cipher(const int64_t *input, size_t length, uint8_t *output,
                       size_t output_capacity)
{
    if (input == NULL || length < 6 || length > 4 + 2 * MAX_AUTOKEY_LENGTH) return -1;
    const int64_t mode = input[0], dialect = input[1];
    const int64_t text_length_value = input[2], key_length_value = input[3];
    if ((mode != 0 && mode != 1) || (dialect != 0 && dialect != 1)
        || text_length_value < 1 || text_length_value > MAX_AUTOKEY_LENGTH
        || key_length_value < 1 || key_length_value > MAX_AUTOKEY_LENGTH) return -1;
    const size_t text_length = (size_t)text_length_value;
    const size_t key_length = (size_t)key_length_value;
    if (length != 4 + text_length + key_length) return -1;
    const size_t key_start = 4 + text_length;
    for (size_t i = 0; i < text_length; ++i) {
        const int64_t value = input[4 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
        if (dialect == 1 && mode == 1 && value >= 'A' && value <= 'Z') return -1;
    }
    for (size_t i = 0; i < key_length; ++i) {
        const int64_t value = input[key_start + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    if (output_capacity < text_length || output == NULL) return -2;

    for (size_t i = 0; i < text_length; ++i) {
        const int64_t plain = uppercase_letter(input[4 + i]) - 'A';
        const int64_t key_value = i < key_length ? uppercase_letter(input[key_start + i])
            : mode == 0 ? uppercase_letter(input[4 + i - key_length]) : uppercase_letter(output[i - key_length]);
        const int64_t shift = key_value - 'A';
        const int64_t mapped = mode == 0 ? (plain + shift) % 26 : (plain - shift + 26) % 26;
        int64_t result = 'A' + mapped;
        if (dialect == 1) result += 32;
        output[i] = (uint8_t)result;
    }
    return (int64_t)text_length;
}
