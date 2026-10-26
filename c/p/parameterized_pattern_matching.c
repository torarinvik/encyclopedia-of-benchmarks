#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 24
#define MAX_PATTERN 8
#define ALPHABET 16
#define MAX_OUTPUT_BYTES 200

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static void predecessor_code(const int64_t *symbols, size_t length, int64_t *code)
{
    int64_t last[ALPHABET];
    for (size_t symbol = 0; symbol < ALPHABET; ++symbol) last[symbol] = -1;
    for (size_t index = 0; index < length; ++index) {
        size_t symbol = (size_t)symbols[index];
        code[index] = last[symbol] < 0 ? 0 : (int64_t)index - last[symbol];
        last[symbol] = (int64_t)index;
    }
}

int64_t parameterized_pattern_matching(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > 2 + MAX_TEXT + MAX_PATTERN) return -1;
    int64_t text_length_value = input[0];
    int64_t pattern_length_value = input[1];
    if (text_length_value < 0 || text_length_value > MAX_TEXT ||
        pattern_length_value < 1 || pattern_length_value > MAX_PATTERN) return -1;
    size_t text_length = (size_t)text_length_value;
    size_t pattern_length = (size_t)pattern_length_value;
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 2; index < length; ++index) {
        if (input[index] < 0 || input[index] >= ALPHABET) return -1;
    }

    int64_t pattern_code[MAX_PATTERN] = {0};
    predecessor_code(input + 2 + text_length, pattern_length, pattern_code);
    size_t matches[MAX_TEXT];
    size_t match_count = 0;
    if (pattern_length <= text_length) {
        for (size_t start = 0; start <= text_length - pattern_length; ++start) {
            int64_t window_code[MAX_PATTERN] = {0};
            predecessor_code(input + 2 + start, pattern_length, window_code);
            size_t index = 0;
            while (index < pattern_length && pattern_code[index] == window_code[index]) ++index;
            if (index == pattern_length) matches[match_count++] = start;
        }
    }

    size_t output_bytes = 8 * (match_count + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, (int64_t)match_count);
    for (size_t index = 0; index < match_count; ++index) {
        store_i64_le(staged, 8 * (index + 1), (int64_t)matches[index]);
    }
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
