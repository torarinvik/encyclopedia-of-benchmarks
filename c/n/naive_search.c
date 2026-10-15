/* Find every occurrence of a byte pattern with a direct window scan. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 255
#define MAX_PATTERN_LENGTH 255

int64_t naive_search(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH) return -1;
    if (values[0] < 0 || values[0] > MAX_TEXT_LENGTH ||
        values[1] < 0 || values[1] > MAX_PATTERN_LENGTH) return -1;
    const size_t text_length = (size_t)values[0];
    const size_t pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    const size_t pattern_start = 2 + text_length;
    for (size_t index = 0; index < text_length; ++index)
        if (values[2 + index] < 1 || values[2 + index] > 127) return -1;
    for (size_t index = 0; index < pattern_length; ++index)
        if (values[pattern_start + index] < 1 || values[pattern_start + index] > 127) return -1;

    size_t match_count = 0;
    if (pattern_length <= text_length) {
        for (size_t start = 0; start <= text_length - pattern_length; ++start) {
            size_t offset = 0;
            while (offset < pattern_length &&
                   values[2 + start + offset] == values[pattern_start + offset]) ++offset;
            if (offset == pattern_length) ++match_count;
        }
    }
    if (output_capacity < match_count || (match_count != 0 && output == NULL)) return -2;
    size_t written = 0;
    if (pattern_length <= text_length) {
        for (size_t start = 0; start <= text_length - pattern_length; ++start) {
            size_t offset = 0;
            while (offset < pattern_length &&
                   values[2 + start + offset] == values[pattern_start + offset]) ++offset;
            if (offset == pattern_length) output[written++] = (uint8_t)start;
        }
    }
    return (int64_t)written;
}
