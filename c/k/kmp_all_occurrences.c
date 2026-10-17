#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 256, MAX_PATTERN_LENGTH = 64, MAX_INPUT_LENGTH = 322 };

int64_t kmp_all_occurrences(const int64_t *values, size_t length,
                            uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t text_length_value = values[0];
    const int64_t pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > MAX_TEXT_LENGTH ||
        pattern_length_value < 1 || pattern_length_value > MAX_PATTERN_LENGTH) return -1;
    const size_t text_length = (size_t)text_length_value;
    const size_t pattern_length = (size_t)pattern_length_value;
    if (length != 2 + text_length + pattern_length) return -1;
    const size_t pattern_offset = 2 + text_length;
    for (size_t i = 0; i < text_length + pattern_length; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 127) return -1;

    size_t prefix[MAX_PATTERN_LENGTH] = {0};
    for (size_t i = 1; i < pattern_length; ++i) {
        size_t matched = prefix[i - 1];
        while (matched > 0 && values[pattern_offset + i] != values[pattern_offset + matched])
            matched = prefix[matched - 1];
        if (values[pattern_offset + i] == values[pattern_offset + matched]) ++matched;
        prefix[i] = matched;
    }

    size_t matches[MAX_TEXT_LENGTH];
    size_t match_count = 0;
    size_t matched = 0;
    for (size_t i = 0; i < text_length; ++i) {
        while (matched > 0 && values[2 + i] != values[pattern_offset + matched])
            matched = prefix[matched - 1];
        if (values[2 + i] == values[pattern_offset + matched]) ++matched;
        if (matched == pattern_length) {
            matches[match_count++] = i + 1 - pattern_length;
            matched = prefix[matched - 1];
        }
    }

    const size_t output_bytes = match_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < match_count; ++i) {
        const uint64_t bits = (uint64_t)matches[i];
        for (size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
