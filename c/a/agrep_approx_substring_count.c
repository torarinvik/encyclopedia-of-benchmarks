#include <stddef.h>
#include <stdint.h>

#define MAX_PATTERN_LENGTH 63
#define MAX_TEXT_LENGTH 4096
#define MAX_ERRORS 2

int64_t agrep_approx_substring_count(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || values[0] < 1 || values[0] > MAX_PATTERN_LENGTH ||
        values[1] < 0 || values[1] > MAX_TEXT_LENGTH || values[2] < 0 || values[2] > MAX_ERRORS)
        return -2;
    const size_t pattern_length = (size_t)values[0];
    const size_t text_length = (size_t)values[1];
    const int64_t max_errors = values[2];
    if (length != 3 + pattern_length + text_length) return -2;
    for (size_t i = 3; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;

    int64_t previous[MAX_PATTERN_LENGTH + 1];
    int64_t current[MAX_PATTERN_LENGTH + 1];
    for (size_t j = 0; j <= pattern_length; ++j) previous[j] = (int64_t)j;
    int64_t matches = 0;
    const size_t text_offset = 3 + pattern_length;
    for (size_t i = 0; i < text_length; ++i) {
        current[0] = 0;
        for (size_t j = 1; j <= pattern_length; ++j) {
            const int64_t substitution = previous[j - 1] +
                (values[3 + j - 1] == values[text_offset + i] ? 0 : 1);
            int64_t best = previous[j] + 1;
            if (current[j - 1] + 1 < best) best = current[j - 1] + 1;
            if (substitution < best) best = substitution;
            current[j] = best;
        }
        if (current[pattern_length] <= max_errors) ++matches;
        for (size_t j = 0; j <= pattern_length; ++j) previous[j] = current[j];
    }
    return matches;
}
