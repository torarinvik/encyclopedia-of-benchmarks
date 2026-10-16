#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 128
#define MAX_PATTERN_LENGTH 64
#define MAX_PARSEABLE_LENGTH (2 + MAX_TEXT_LENGTH + MAX_PATTERN_LENGTH + 1)

int64_t substring_search(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -2;
    const int64_t text_length = values[0], pattern_length = values[1];
    if (text_length < 0 || text_length > MAX_TEXT_LENGTH ||
        pattern_length < 0 || pattern_length > MAX_PATTERN_LENGTH ||
        length != 2 + (size_t)text_length + (size_t)pattern_length) return -2;
    const size_t text_start = 2, pattern_start = text_start + (size_t)text_length;
    for (size_t i = text_start; i < length; ++i)
        if (values[i] < 1 || values[i] > 127) return -2;

    size_t text_index = 0, pattern_index = 0;
    int64_t match_start = -1;
    while (text_index < (size_t)text_length) {
        const int64_t expected = pattern_index < (size_t)pattern_length
            ? values[pattern_start + pattern_index] : 0;
        if (values[text_start + text_index] == expected) {
            if (match_start == -1) match_start = (int64_t)text_index;
            ++pattern_index;
            if (pattern_index == (size_t)pattern_length) return match_start;
            ++text_index;
        } else {
            match_start = -1;
            pattern_index = 0;
            ++text_index;
        }
    }
    return -1;
}
