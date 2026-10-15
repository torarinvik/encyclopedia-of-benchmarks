/* All-match Boyer-Moore search with Apostolico-Giancarlo suffix memory. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 512
#define MAX_SEQUENCE_LENGTH 255

static size_t collect_matches(const int64_t *values, size_t text_length,
                              size_t pattern_length, size_t pattern_start,
                              uint8_t positions[MAX_SEQUENCE_LENGTH])
{
    size_t bad_shift[128];
    bool present[128];
    size_t suffix_skip[256];
    for (size_t byte = 0; byte < 128; ++byte) {
        bad_shift[byte] = 0;
        present[byte] = false;
    }
    for (size_t shift = 0; shift < 256; ++shift) suffix_skip[shift] = 0;
    for (size_t index = 0; index + 1 < pattern_length; ++index) {
        const size_t byte = (size_t)values[pattern_start + index];
        bad_shift[byte] = pattern_length - index - 1;
        present[byte] = true;
    }
    for (size_t byte = 0; byte < 128; ++byte) {
        if (!present[byte]) continue;
        const size_t shift = bad_shift[byte];
        size_t matched = 0;
        while (matched < pattern_length - shift &&
               values[pattern_start + pattern_length - 1 - matched] ==
                   values[pattern_start + pattern_length - 1 - shift - matched]) ++matched;
        suffix_skip[shift] = matched;
    }

    size_t count = 0;
    size_t start = 0;
    size_t jump = pattern_length;
    while (start <= text_length - pattern_length) {
        const size_t skip = suffix_skip[jump];
        int index = (int)pattern_length - 1;
        while (index >= 0) {
            if (values[2 + start + (size_t)index] != values[pattern_start + (size_t)index]) {
                const size_t mismatch = (size_t)values[2 + start + (size_t)index];
                jump = present[mismatch] ? bad_shift[mismatch] : pattern_length;
                start += jump;
                break;
            }
            if ((size_t)index == pattern_length - jump) index -= (int)skip;
            if (index == 0) {
                positions[count++] = (uint8_t)start;
                jump = 1;
                ++start;
                break;
            }
            --index;
        }
    }
    return count;
}

int64_t boyer_moore_ag(const int64_t *values, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 0 || values[0] > MAX_SEQUENCE_LENGTH ||
        values[1] < 1 || values[1] > MAX_SEQUENCE_LENGTH) return -1;
    const size_t text_length = (size_t)values[0];
    const size_t pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;

    uint8_t positions[MAX_SEQUENCE_LENGTH];
    const size_t count = pattern_length > text_length ? 0 :
        collect_matches(values, text_length, pattern_length, 2 + text_length, positions);
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < count; ++index) output[index] = positions[index];
    return (int64_t)count;
}
