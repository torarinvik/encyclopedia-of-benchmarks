#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 260
#define MAX_TEXT_LENGTH 256
#define MAX_KEY 256

int64_t skytale_cipher(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 1 || input[1] < 1 || input[1] > MAX_KEY ||
        input[2] < 0 || input[2] > MAX_TEXT_LENGTH) return -1;
    const size_t mode = (size_t)input[0], key = (size_t)input[1], n = (size_t)input[2];
    if (length != 3 + n) return -1;
    for (size_t i = 0; i < n; ++i) if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    if (output == NULL || capacity < n) return -2;

    if (mode == 0) {
        size_t out = 0;
        for (size_t row = 0; row < key; ++row)
            for (size_t position = row; position < n; position += key)
                output[out++] = (uint8_t)input[3 + position];
    } else {
        size_t starts[MAX_KEY] = {0}, used[MAX_KEY] = {0};
        const size_t base = n / key, extra = n % key;
        for (size_t row = 1; row < key; ++row)
            starts[row] = starts[row - 1] + base + (row - 1 < extra ? 1 : 0);
        for (size_t position = 0; position < n; ++position) {
            const size_t row = position % key;
            output[position] = (uint8_t)input[3 + starts[row] + used[row]++];
        }
    }
    return (int64_t)n;
}
