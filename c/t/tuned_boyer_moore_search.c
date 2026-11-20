/* Bounded all-occurrences Tuned Boyer–Moore search. */
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define TUNED_MAX_TEXT 255
#define TUNED_MAX_PATTERN 64
#define TUNED_MAX_FRAME 322
#define TUNED_ALPHABET 128
#define TUNED_MAX_PADDED (TUNED_MAX_TEXT + TUNED_MAX_PATTERN)

static void tuned_store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t tuned_boyer_moore_search(const int64_t *input, size_t length,
                                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > TUNED_MAX_FRAME) return -1;
    if (input[0] < 0 || input[0] > TUNED_MAX_TEXT ||
        input[1] < 1 || input[1] > TUNED_MAX_PATTERN) return -1;
    const size_t text_length = (size_t)input[0];
    const size_t pattern_length = (size_t)input[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 127) return -1;

    int64_t positions[TUNED_MAX_TEXT];
    size_t match_count = 0;
    if (pattern_length <= text_length) {
        uint8_t padded[TUNED_MAX_PADDED];
        size_t shifts[TUNED_ALPHABET];
        const size_t pattern_start = 2 + text_length;
        const uint8_t final_byte = (uint8_t)input[pattern_start + pattern_length - 1];
        for (size_t index = 0; index < text_length; ++index) padded[index] = (uint8_t)input[2 + index];
        for (size_t index = 0; index < pattern_length; ++index) padded[text_length + index] = final_byte;
        for (size_t byte = 0; byte < TUNED_ALPHABET; ++byte) shifts[byte] = pattern_length;
        for (size_t index = 0; index + 1 < pattern_length; ++index)
            shifts[(size_t)input[pattern_start + index]] = pattern_length - index - 1;
        const size_t final_shift = shifts[final_byte];
        shifts[final_byte] = 0;

        for (size_t alignment = 0; alignment < text_length;) {
            size_t skip = shifts[padded[alignment + pattern_length - 1]];
            while (skip != 0) {
                alignment += skip;
                skip = shifts[padded[alignment + pattern_length - 1]];
                alignment += skip;
                skip = shifts[padded[alignment + pattern_length - 1]];
                alignment += skip;
                skip = shifts[padded[alignment + pattern_length - 1]];
            }
            bool prefix_matches = true;
            for (size_t index = 0; index + 1 < pattern_length; ++index) {
                if ((uint8_t)input[pattern_start + index] != padded[alignment + index]) {
                    prefix_matches = false;
                    break;
                }
            }
            if (prefix_matches && alignment < text_length)
                positions[match_count++] = (int64_t)alignment;
            alignment += final_shift;
        }
    }

    const size_t output_bytes = match_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < match_count; ++index)
        tuned_store_i64_le(output, index * 8, positions[index]);
    return (int64_t)output_bytes;
}
