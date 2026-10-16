#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 256
#define MAX_CHARACTER_LENGTH 128

static int contains_character(int64_t value, const int64_t *input,
                              size_t set_start, int64_t set_length) {
    if (set_length == -1)
        return value == 9 || value == 10 || value == 13 || value == 32;
    for (size_t i = 0; i < (size_t)set_length; ++i)
        if (input[set_start + i] == value) return 1;
    return 0;
}

int64_t strip(const int64_t *input, size_t length, uint8_t *output,
              size_t output_capacity) {
    if (input == NULL || length < 2 || length > 386) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT_LENGTH) return -1;
    size_t text_length = (size_t)input[0];
    size_t set_index = 1 + text_length;
    if (set_index >= length) return -1;
    int64_t set_length = input[set_index];
    size_t expected_length;
    if (set_length == -1) {
        expected_length = set_index + 1;
    } else {
        if (set_length < 0 || set_length > MAX_CHARACTER_LENGTH) return -1;
        expected_length = set_index + 1 + (size_t)set_length;
    }
    if (length != expected_length) return -1;
    for (size_t i = 0; i < text_length; ++i)
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    if (set_length >= 0)
        for (size_t i = 0; i < (size_t)set_length; ++i)
            if (input[set_index + 1 + i] < 0 || input[set_index + 1 + i] > 127) return -1;

    size_t start = 0, end = text_length;
    while (start < end && contains_character(input[1 + start], input,
                                               set_index + 1, set_length)) ++start;
    while (end > start && contains_character(input[end], input,
                                               set_index + 1, set_length)) --end;
    size_t output_length = end - start;
    if (output_capacity < output_length || (output_length > 0 && output == NULL)) return -2;
    for (size_t i = 0; i < output_length; ++i)
        output[i] = (uint8_t)input[1 + start + i];
    return (int64_t)output_length;
}
