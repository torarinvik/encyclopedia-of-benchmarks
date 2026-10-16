#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 512

static int is_ascii_letter(int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

int64_t wave_string(const int64_t *values, size_t length,
                    uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > MAX_TEXT_LENGTH ||
        length != 1 + (size_t)values[0]) return -1;
    const size_t text_length = (size_t)values[0];
    size_t letter_count = 0;
    for (size_t index = 0; index < text_length; ++index) {
        if (values[index + 1] < 32 || values[index + 1] > 126) return -1;
        if (is_ascii_letter(values[index + 1])) ++letter_count;
    }
    const size_t output_length = letter_count * (text_length + 2);
    if (output_length > output_capacity || (output_length > 0 && output == NULL)) return -2;

    size_t written = 0;
    for (size_t position = 0; position < text_length; ++position) {
        if (!is_ascii_letter(values[position + 1])) continue;
        output[written++] = (uint8_t)(text_length & 255);
        output[written++] = (uint8_t)(text_length >> 8);
        for (size_t index = 0; index < text_length; ++index) {
            int64_t byte = values[index + 1];
            if (index == position && byte >= 'a' && byte <= 'z') byte -= 32;
            output[written++] = (uint8_t)byte;
        }
    }
    return (int64_t)letter_count;
}
