#include <stddef.h>
#include <stdint.h>

#define MAX_MESSAGE_LENGTH 64
#define KEY_COUNT 26

int64_t brute_force_caesar_cipher(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (length > MAX_MESSAGE_LENGTH || (length > 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127) return -1;

    const size_t needed = length * KEY_COUNT + (KEY_COUNT - 1);
    if (output == NULL || capacity < needed) return -2;
    size_t position = 0;
    for (size_t key = 0; key < KEY_COUNT; ++key) {
        for (size_t i = 0; i < length; ++i) {
            int64_t value = input[i];
            if (value >= 'A' && value <= 'Z') value = 'A' + (value - 'A' + 26 - (int64_t)key) % 26;
            output[position++] = (uint8_t)value;
        }
        if (key + 1 < KEY_COUNT) output[position++] = (uint8_t)'\n';
    }
    return KEY_COUNT;
}
