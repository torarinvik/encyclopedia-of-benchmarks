#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 4096

int64_t remove_duplicate_characters(const int64_t *values, size_t length,
                                    uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > MAX_INPUT_LENGTH ||
        length != 1 + (size_t)values[0]) return -1;
    const size_t text_length = (size_t)values[0];
    for (size_t index = 0; index < text_length; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 127) return -1;

    uint8_t seen[128] = {0};
    size_t output_length = 0;
    for (size_t index = 0; index < text_length; ++index) {
        const uint8_t byte = (uint8_t)values[index + 1];
        if (!seen[byte]) {
            seen[byte] = 1;
            ++output_length;
        }
    }
    if (output_length > output_capacity || (output_length > 0 && output == NULL)) return -2;

    for (size_t index = 0; index < 128; ++index) seen[index] = 0;
    size_t written = 0;
    for (size_t index = 0; index < text_length; ++index) {
        const uint8_t byte = (uint8_t)values[index + 1];
        if (!seen[byte]) {
            seen[byte] = 1;
            output[written++] = byte;
        }
    }
    return (int64_t)written;
}
