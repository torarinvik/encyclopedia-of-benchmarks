/* Return the first ASCII byte match using bad-character and good-suffix shifts. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PATTERN_LENGTH 4096
#define ALPHABET_SIZE 127

int64_t boyer_moore(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 2 + 2 * MAX_PATTERN_LENGTH) return -1;
    if (values[0] < 0 || values[0] > MAX_PATTERN_LENGTH ||
        values[1] < 0 || values[1] > MAX_PATTERN_LENGTH) return -1;
    const size_t text_length = (size_t)values[0];
    const size_t pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] >= ALPHABET_SIZE) return -1;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const size_t pattern_start = 2 + text_length;
    int64_t last_occurrence[ALPHABET_SIZE];
    for (size_t byte = 0; byte < ALPHABET_SIZE; ++byte) last_occurrence[byte] = -1;
    for (size_t index = 0; index < pattern_length; ++index)
        last_occurrence[(size_t)values[pattern_start + index]] = (int64_t)index;

    size_t good_suffix[MAX_PATTERN_LENGTH + 1] = {0};
    size_t border_position[MAX_PATTERN_LENGTH + 1] = {0};
    size_t i = pattern_length;
    size_t j = pattern_length + 1;
    border_position[i] = j;
    while (i > 0) {
        while (j <= pattern_length && values[pattern_start + i - 1] != values[pattern_start + j - 1]) {
            if (good_suffix[j] == 0) good_suffix[j] = j - i;
            j = border_position[j];
        }
        --i;
        --j;
        border_position[i] = j;
    }
    j = border_position[0];
    for (i = 0; i <= pattern_length; ++i) {
        if (good_suffix[i] == 0) good_suffix[i] = j;
        if (i == j) j = border_position[j];
    }

    size_t alignment = 0;
    while (alignment <= text_length - pattern_length) {
        size_t pattern_index = pattern_length;
        while (pattern_index > 0 &&
               values[pattern_start + pattern_index - 1] == values[2 + alignment + pattern_index - 1])
            --pattern_index;
        if (pattern_index == 0) return (int64_t)alignment;

        const size_t text_byte = (size_t)values[2 + alignment + pattern_index - 1];
        int64_t bad_shift = (int64_t)(pattern_index - 1) - last_occurrence[text_byte];
        if (bad_shift < 1) bad_shift = 1;
        const size_t shift = good_suffix[pattern_index] > (size_t)bad_shift
            ? good_suffix[pattern_index] : (size_t)bad_shift;
        alignment += shift;
    }
    return -1;
}
