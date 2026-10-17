#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 256
#define MAX_PATTERN_LENGTH 32
#define ALPHABET_SIZE 128
#define STATE_COUNT (MAX_PATTERN_LENGTH + 1)
#define MAX_INPUT_LENGTH (2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_LENGTH + 1)
#define MAX_OUTPUT_BYTES (4 * MAX_TEXT_LENGTH)

static size_t next_state(const int64_t *pattern, size_t pattern_length,
                         size_t state, int64_t symbol) {
    if (state < pattern_length && symbol == pattern[state]) return state + 1;
    for (size_t candidate = state; candidate > 0; --candidate) {
        if (pattern[candidate - 1] != symbol) continue;
        bool prefix_matches = true;
        for (size_t i = 0; i + 1 < candidate; ++i) {
            if (pattern[i] != pattern[state - candidate + i + 1]) {
                prefix_matches = false;
                break;
            }
        }
        if (prefix_matches) return candidate;
    }
    return 0;
}

static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t string_match_finite_automata(const int64_t *values, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_text_length = values[0];
    const int64_t raw_pattern_length = values[1];
    if (raw_text_length < 0 || raw_text_length > MAX_TEXT_LENGTH ||
        raw_pattern_length < 1 || raw_pattern_length > MAX_PATTERN_LENGTH ||
        length != 2 + (size_t)raw_text_length + (size_t)raw_pattern_length) return -1;
    const size_t text_length = (size_t)raw_text_length;
    const size_t pattern_length = (size_t)raw_pattern_length;
    for (size_t i = 0; i < text_length + pattern_length; ++i)
        if (values[2 + i] < 0 || values[2 + i] >= ALPHABET_SIZE) return -1;

    const int64_t *text = values + 2;
    const int64_t *pattern = text + text_length;
    int32_t transitions[STATE_COUNT][ALPHABET_SIZE];
    for (size_t state = 0; state <= pattern_length; ++state)
        for (size_t symbol = 0; symbol < ALPHABET_SIZE; ++symbol)
            transitions[state][symbol] =
                (int32_t)next_state(pattern, pattern_length, state, (int64_t)symbol);

    int32_t matches[MAX_TEXT_LENGTH];
    size_t match_count = 0;
    size_t state = 0;
    for (size_t index = 0; index < text_length; ++index) {
        state = (size_t)transitions[state][(size_t)text[index]];
        if (state == pattern_length)
            matches[match_count++] = (int32_t)(index + 1 - pattern_length);
    }

    const size_t byte_count = 4 * match_count;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t index = 0; index < match_count; ++index)
        store_i32_le(output, 4 * index, matches[index]);
    return (int64_t)byte_count;
}
