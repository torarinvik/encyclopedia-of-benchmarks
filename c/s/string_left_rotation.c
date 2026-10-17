#include <stddef.h>
#include <stdint.h>

enum { MAX_STRING_LENGTH = 256, MAX_PARSEABLE_INPUT_LENGTH = 259 };

int64_t string_left_rotation(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_length = input[0];
    const int64_t raw_rotation = input[1];
    if (raw_length < 0 || raw_length > MAX_STRING_LENGTH ||
        raw_rotation < 0 || raw_rotation > raw_length ||
        length != (size_t)raw_length + 2) return -1;

    const size_t text_length = (size_t)raw_length;
    const size_t rotation = (size_t)raw_rotation;
    uint16_t units[MAX_STRING_LENGTH];
    for (size_t i = 0; i < text_length; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 65535) return -1;
        units[i] = (uint16_t)input[i + 2];
    }
    const size_t required = text_length * 2;
    if (required == 0) return 0;
    if (output == NULL || capacity < required) return -2;

    for (size_t i = 0; i < text_length; ++i) {
        size_t source = rotation + i;
        if (source >= text_length) source -= text_length;
        const uint16_t value = units[source];
        output[2 * i] = (uint8_t)(value & 255u);
        output[2 * i + 1] = (uint8_t)(value >> 8);
    }
    return (int64_t)required;
}
