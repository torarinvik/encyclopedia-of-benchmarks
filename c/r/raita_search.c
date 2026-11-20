/* Bounded all-occurrences Raita search with Horspool shifts. */
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define RAITA_MAX_TEXT 255
#define RAITA_MAX_PATTERN 64
#define RAITA_MAX_FRAME 322
#define RAITA_ALPHABET 128

static void raita_store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t raita_search(const int64_t *input, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > RAITA_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > RAITA_MAX_TEXT ||
        input[1] < 1 || input[1] > RAITA_MAX_PATTERN) return -1;
    const size_t text_length = (size_t)input[0];
    const size_t pattern_length = (size_t)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (input[2 + index] < 0 || input[2 + index] >= RAITA_ALPHABET) return -1;

    const int64_t *text = input + 2;
    const int64_t *pattern = text + text_length;
    int64_t positions[RAITA_MAX_TEXT];
    size_t match_count = 0;
    if (pattern_length <= text_length) {
        size_t shift[RAITA_ALPHABET];
        for (size_t byte = 0; byte < RAITA_ALPHABET; ++byte) shift[byte] = pattern_length;
        for (size_t index = 0; index + 1 < pattern_length; ++index)
            shift[(size_t)pattern[index]] = pattern_length - index - 1;
        const size_t middle = pattern_length / 2;
        for (size_t alignment = 0; alignment <= text_length - pattern_length;) {
            const size_t last = (size_t)text[alignment + pattern_length - 1];
            bool matches = pattern[pattern_length - 1] == (int64_t)last;
            if (matches) matches = pattern[0] == text[alignment];
            if (matches) matches = pattern[middle] == text[alignment + middle];
            if (matches) {
                for (size_t index = 1; index + 1 < pattern_length; ++index) {
                    if (pattern[index] != text[alignment + index]) {
                        matches = false;
                        break;
                    }
                }
                if (matches) positions[match_count++] = (int64_t)alignment;
            }
            alignment += shift[last];
        }
    }
    const size_t output_bytes = match_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < match_count; ++index)
        raita_store_i64_le(output, index * 8, positions[index]);
    return (int64_t)output_bytes;
}
