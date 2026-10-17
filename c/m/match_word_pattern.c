#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PATTERN_LENGTH 8
#define MAX_TEXT_LENGTH 32
#define MAX_INPUT_LENGTH 43

static bool match_word_pattern_search(const int64_t *pattern, size_t pattern_length,
                                      const int64_t *text, size_t text_length,
                                      size_t pattern_index, size_t text_index,
                                      size_t *mapped_start, size_t *mapped_length)
{
    if (pattern_index == pattern_length) return text_index == text_length;
    if (text_index == text_length) return false;

    const size_t symbol = (size_t)pattern[pattern_index];
    const size_t known_length = mapped_length[symbol];
    if (known_length != 0) {
        if (known_length > text_length - text_index) return false;
        for (size_t offset = 0; offset < known_length; ++offset) {
            if (text[mapped_start[symbol] + offset] != text[text_index + offset]) return false;
        }
        return match_word_pattern_search(pattern, pattern_length, text, text_length,
                                         pattern_index + 1, text_index + known_length,
                                         mapped_start, mapped_length);
    }

    for (size_t end = text_index + 1; end <= text_length; ++end) {
        const size_t candidate_length = end - text_index;
        bool already_used = false;
        for (size_t other_index = 0; other_index < pattern_index; ++other_index) {
            const size_t other = (size_t)pattern[other_index];
            if (other == symbol) continue;
            if (mapped_length[other] != candidate_length) continue;
            bool equal = true;
            for (size_t offset = 0; offset < candidate_length; ++offset) {
                if (text[mapped_start[other] + offset] != text[text_index + offset]) {
                    equal = false;
                    break;
                }
            }
            if (equal) {
                already_used = true;
                break;
            }
        }
        if (already_used) continue;

        mapped_start[symbol] = text_index;
        mapped_length[symbol] = candidate_length;
        if (match_word_pattern_search(pattern, pattern_length, text, text_length,
                                      pattern_index + 1, end, mapped_start, mapped_length)) {
            return true;
        }
        mapped_length[symbol] = 0;
    }
    return false;
}

int64_t match_word_pattern(const int64_t *input, size_t input_length)
{
    if (input == NULL || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_PATTERN_LENGTH
        || input[1] < 0 || input[1] > MAX_TEXT_LENGTH) return -1;
    const size_t pattern_length = (size_t)input[0];
    const size_t text_length = (size_t)input[1];
    if (input_length != 2 + pattern_length + text_length) return -1;
    for (size_t index = 0; index < pattern_length + text_length; ++index) {
        if (input[2 + index] < 0 || input[2 + index] > 127) return -1;
    }

    size_t mapped_start[128] = {0};
    size_t mapped_length[128] = {0};
    return match_word_pattern_search(input + 2, pattern_length,
                                     input + 2 + pattern_length, text_length,
                                     0, 0, mapped_start, mapped_length) ? 1 : 0;
}
