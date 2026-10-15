/* Return the first ASCII byte match using Boyer-Moore's bad-character rule. */
#include <stddef.h>
#include <stdint.h>

int64_t boyer_moore_search(const int64_t *input_values, size_t length)
{
    if (input_values == NULL || length < 2 || length > 8194) return -1;
    if (input_values[0] < 0 || input_values[0] > 4096 ||
        input_values[1] < 0 || input_values[1] > 4096) return -1;
    const size_t text_length = (size_t)input_values[0];
    const size_t pattern_length = (size_t)input_values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (input_values[2 + index] < 0 || input_values[2 + index] > 127) return -1;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const size_t pattern_start = 2 + text_length;
    int64_t last_occurrence[128];
    for (size_t value = 0; value < 128; ++value) last_occurrence[value] = -1;
    for (size_t index = 0; index < pattern_length; ++index)
        last_occurrence[(size_t)input_values[pattern_start + index]] = (int64_t)index;

    size_t alignment = 0;
    while (alignment <= text_length - pattern_length) {
        size_t pattern_index = pattern_length;
        while (pattern_index > 0 &&
               input_values[pattern_start + pattern_index - 1] == input_values[2 + alignment + pattern_index - 1])
            --pattern_index;
        if (pattern_index == 0) return (int64_t)alignment;
        const int64_t text_byte = input_values[2 + alignment + pattern_index - 1];
        int64_t shift = (int64_t)(pattern_index - 1) - last_occurrence[(size_t)text_byte];
        if (shift < 1) shift = 1;
        alignment += (size_t)shift;
    }
    return -1;
}
