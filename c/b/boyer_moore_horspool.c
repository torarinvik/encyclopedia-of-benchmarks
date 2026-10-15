/* Find every ASCII byte match with the Boyer-Moore-Horspool shift rule. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 512
#define MAX_SEQUENCE_LENGTH 255

static size_t count_matches(const int64_t *values, size_t text_length, size_t pattern_length,
                            size_t pattern_start, const size_t shifts[128])
{
    if (pattern_length == 0) return text_length + 1;
    if (pattern_length > text_length) return 0;
    size_t count = 0;
    size_t start = 0;
    while (start <= text_length - pattern_length) {
        size_t current = pattern_length;
        while (current > 0 &&
               values[pattern_start + current - 1] == values[2 + start + current - 1]) --current;
        if (current == 0) {
            ++count;
            ++start;
        } else {
            const size_t tail = (size_t)values[2 + start + pattern_length - 1];
            start += shifts[tail];
        }
    }
    return count;
}

int64_t boyer_moore_horspool(const int64_t *values, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 || values[0] > MAX_SEQUENCE_LENGTH ||
        values[1] < 0 || values[1] > MAX_SEQUENCE_LENGTH) return -1;
    const size_t text_length = (size_t)values[0];
    const size_t pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    const size_t pattern_start = 2 + text_length;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;

    size_t shifts[128];
    for (size_t byte = 0; byte < 128; ++byte) shifts[byte] = pattern_length;
    for (size_t index = 0; index + 1 < pattern_length; ++index)
        shifts[(size_t)values[pattern_start + index]] = pattern_length - 1 - index;
    const size_t match_count = count_matches(values, text_length, pattern_length, pattern_start, shifts);
    if (output_capacity < match_count || (match_count != 0 && output == NULL)) return -2;

    size_t written = 0;
    if (pattern_length == 0) {
        for (size_t position = 0; position <= text_length; ++position)
            output[written++] = (uint8_t)position;
    } else if (pattern_length <= text_length) {
        size_t start = 0;
        while (start <= text_length - pattern_length) {
            size_t current = pattern_length;
            while (current > 0 &&
                   values[pattern_start + current - 1] == values[2 + start + current - 1]) --current;
            if (current == 0) {
                output[written++] = (uint8_t)start;
                ++start;
            } else {
                const size_t tail = (size_t)values[2 + start + pattern_length - 1];
                start += shifts[tail];
            }
        }
    }
    return (int64_t)written;
}
