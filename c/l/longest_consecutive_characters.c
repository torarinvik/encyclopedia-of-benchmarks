#include <stddef.h>
#include <stdint.h>

int64_t longest_consecutive_characters(const int64_t *values, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > 257) return -1;
    int64_t count_value = values[0];
    if (count_value < 1 || count_value > 256 || length != (size_t)count_value + 1) return -1;
    size_t count = (size_t)count_value;
    for (size_t i = 0; i < count; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 127) return -1;
    if (output == NULL || capacity < 3) return -2;

    int64_t best_character = values[1];
    size_t best_length = 1, current_length = 1;
    for (size_t i = 1; i < count; ++i) {
        if (values[i + 1] == values[i]) {
            ++current_length;
            if (current_length > best_length) {
                best_length = current_length;
                best_character = values[i + 1];
            }
        } else {
            current_length = 1;
        }
    }
    output[0] = (uint8_t)best_character;
    output[1] = (uint8_t)(best_length & 255);
    output[2] = (uint8_t)(best_length >> 8);
    return 3;
}
