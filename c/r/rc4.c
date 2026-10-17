#include <stddef.h>
#include <stdint.h>

#define MAX_KEY_LENGTH 256
#define MAX_PLAINTEXT_LENGTH 256
#define MAX_INPUT_VALUES 515

int64_t rc4(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t key_length_value = input[0];
    const int64_t plaintext_length_value = input[1];
    if (key_length_value < 1 || key_length_value > MAX_KEY_LENGTH ||
        plaintext_length_value < 0 || plaintext_length_value > MAX_PLAINTEXT_LENGTH) return -1;
    const size_t key_length = (size_t)key_length_value;
    const size_t plaintext_length = (size_t)plaintext_length_value;
    if (length != 2 + key_length + plaintext_length) return -1;
    for (size_t index = 0; index < key_length + plaintext_length; ++index) {
        const int64_t byte = input[2 + index];
        if (byte < 0 || byte > 255) return -1;
    }
    if (plaintext_length == 0) return 0;
    if (output == NULL || capacity < plaintext_length) return -2;

    uint8_t state[256];
    for (size_t index = 0; index < 256; ++index) state[index] = (uint8_t)index;
    size_t j = 0;
    for (size_t index = 0; index < 256; ++index) {
        j = (j + state[index] + (size_t)input[2 + (index % key_length)]) & 255;
        const uint8_t temporary = state[index];
        state[index] = state[j];
        state[j] = temporary;
    }

    size_t i = 0;
    j = 0;
    for (size_t offset = 0; offset < plaintext_length; ++offset) {
        i = (i + 1) & 255;
        j = (j + state[i]) & 255;
        const uint8_t temporary = state[i];
        state[i] = state[j];
        state[j] = temporary;
        const size_t stream_index = (state[i] + state[j]) & 255;
        const uint8_t plaintext = (uint8_t)input[2 + key_length + offset];
        output[offset] = plaintext ^ state[stream_index];
    }
    return (int64_t)plaintext_length;
}
