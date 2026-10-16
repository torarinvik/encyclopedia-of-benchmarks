#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 4096
#define MAX_PATTERN_LENGTH 63

int64_t bitap_string_match(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || values[0] < 0 || values[0] > MAX_TEXT_LENGTH ||
        values[1] < 0 || values[1] > MAX_PATTERN_LENGTH) return -2;
    const size_t text_length = (size_t)values[0];
    const size_t pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -2;
    for (size_t index = 2; index < length; ++index)
        if (values[index] < 'a' || values[index] > 'z') return -2;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    uint64_t masks[26];
    for (size_t letter = 0; letter < 26; ++letter) masks[letter] = UINT64_MAX;
    for (size_t index = 0; index < pattern_length; ++index) {
        const size_t letter = (size_t)(values[2 + text_length + index] - 'a');
        masks[letter] &= ~(UINT64_C(1) << index);
    }
    uint64_t state = ~UINT64_C(1);
    for (size_t index = 0; index < text_length; ++index) {
        const size_t letter = (size_t)(values[2 + index] - 'a');
        state |= masks[letter];
        state <<= 1;
        if ((state & (UINT64_C(1) << pattern_length)) == 0)
            return (int64_t)index - (int64_t)pattern_length + 1;
    }
    return -1;
}
