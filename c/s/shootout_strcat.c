#include <stddef.h>
#include <stdint.h>

enum { MAX_APPEND_COUNT = 4096, MAX_TEXT_BYTES = MAX_APPEND_COUNT * 6 };

int64_t shootout_strcat(int64_t append_count, uint8_t *output, size_t output_capacity)
{
    if (append_count < 0 || append_count > MAX_APPEND_COUNT) return -1;

    uint8_t text[MAX_TEXT_BYTES + 1] = {0};
    size_t length = 0;
    size_t buffer_capacity = 32;
    static const uint8_t suffix[6] = {'h', 'e', 'l', 'l', 'o', '\n'};
    for (int64_t append = 0; append < append_count; ++append) {
        if (buffer_capacity - length < sizeof(suffix) + 1) buffer_capacity *= 2;
        for (size_t index = 0; index < sizeof(suffix); ++index)
            text[length + index] = suffix[index];
        length += sizeof(suffix);
        text[length] = 0;
    }

    uint8_t staged[6];
    uint8_t reversed[5];
    size_t digit_count = 0;
    size_t output_length = 0;
    size_t value = length;
    do {
        reversed[digit_count++] = (uint8_t)('0' + value % 10);
        value /= 10;
    } while (value != 0);
    while (digit_count > 0) staged[output_length++] = reversed[--digit_count];
    staged[output_length++] = '\n';

    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return (int64_t)output_length;
}
