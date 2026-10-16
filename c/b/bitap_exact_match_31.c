#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 4096
#define MAX_PATTERN_LENGTH 31

int64_t bitap_exact_match_31(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || values[0] < 0 || values[0] > MAX_TEXT_LENGTH ||
        values[1] < 0 || values[1] > MAX_PATTERN_LENGTH) return -2;
    size_t text_length = (size_t)values[0], pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -2;
    for (size_t i = 2; i < length; ++i) if (values[i] < 'a' || values[i] > 'z') return -2;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;
    uint32_t masks[26];
    for (size_t c = 0; c < 26; ++c) masks[c] = UINT32_MAX;
    for (size_t i = 0; i < pattern_length; ++i) masks[(size_t)(values[2 + text_length + i] - 'a')] &= ~(UINT32_C(1) << i);
    uint32_t state = ~UINT32_C(1);
    for (size_t i = 0; i < text_length; ++i) {
        state |= masks[(size_t)(values[2 + i] - 'a')];
        state <<= 1;
        if ((state & (UINT32_C(1) << pattern_length)) == 0) return (int64_t)i - (int64_t)pattern_length + 1;
    }
    return -1;
}
