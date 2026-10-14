/* Direct recursive full-string matching for the . and * regular-expression subset. */
#include <stddef.h>
#include <stdint.h>

static int regex_match_recursive(const int64_t *values, size_t text_length,
                                 size_t pattern_start, size_t pattern_length,
                                 size_t text_index, size_t pattern_index)
{
    if (pattern_index == pattern_length) return text_index == text_length;
    const int64_t atom = values[pattern_start + pattern_index];
    if (pattern_index + 1 < pattern_length && values[pattern_start + pattern_index + 1] == '*') {
        if (regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                  text_index, pattern_index + 2)) return 1;
        return text_index < text_length && (atom == '.' || atom == values[2 + text_index])
            && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                     text_index + 1, pattern_index);
    }
    return text_index < text_length && (atom == '.' || atom == values[2 + text_index])
        && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                 text_index + 1, pattern_index + 1);
}

int64_t regex_match(const int64_t *values, size_t length)
{
    if (length < 2) return -1;
    if (values[0] < 0 || values[0] > 12 || values[1] < 0 || values[1] > 20) return -1;
    const size_t text_length = (size_t)values[0];
    const size_t pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    const size_t pattern_start = 2 + text_length;
    for (size_t index = 0; index < text_length; ++index) {
        if (values[2 + index] < 'a' || values[2 + index] > 'z') return -1;
    }
    for (size_t index = 0; index < pattern_length; ++index) {
        const int64_t symbol = values[pattern_start + index];
        if (!((symbol >= 'a' && symbol <= 'z') || symbol == '.' || symbol == '*')) return -1;
        if (symbol == '*' && (index == 0 || values[pattern_start + index - 1] == '*')) return -1;
    }
    return regex_match_recursive(values, text_length, pattern_start, pattern_length, 0, 0);
}
