#include <stddef.h>
#include <stdint.h>

#define ACS_MAX_TEXT_LENGTH 4096
#define ACS_MAX_PATTERN_LENGTH 128
#define ACS_MAX_PARSEABLE_LENGTH 4227
#define ACS_PATTERN_STORAGE (ACS_MAX_PATTERN_LENGTH + 1)

static void acs_preprocess(const int64_t *pattern, size_t pattern_length,
                           int64_t *kmp_next) {
    int64_t i = 0;
    int64_t j = -1;
    kmp_next[0] = -1;
    while ((size_t)i < pattern_length) {
        while (j > -1 && pattern[i] != pattern[j]) j = kmp_next[j];
        ++i;
        ++j;
        if (pattern[i] == pattern[j]) kmp_next[i] = kmp_next[j];
        else kmp_next[i] = j;
    }
}

int64_t apostolico_crochemore_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > ACS_MAX_PARSEABLE_LENGTH) {
        return -1;
    }

    const int64_t text_length_value = input[0];
    const int64_t pattern_length_value = input[1];
    if (text_length_value < 0 || text_length_value > ACS_MAX_TEXT_LENGTH
        || pattern_length_value < 1
        || pattern_length_value > ACS_MAX_PATTERN_LENGTH) {
        return -1;
    }
    const size_t text_length = (size_t)text_length_value;
    const size_t pattern_length = (size_t)pattern_length_value;
    if (length != 2 + text_length + pattern_length) return -1;

    const size_t pattern_start = 2 + text_length;
    int64_t pattern[ACS_PATTERN_STORAGE];
    for (size_t index = 0; index < text_length; ++index) {
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;
    }
    for (size_t index = 0; index < pattern_length; ++index) {
        const int64_t byte = input[pattern_start + index];
        if (byte < 0 || byte > 3) return -1;
        pattern[index] = byte;
    }
    pattern[pattern_length] = 4;

    int64_t kmp_next[ACS_PATTERN_STORAGE];
    acs_preprocess(pattern, pattern_length, kmp_next);

    int64_t ell = 1;
    while ((size_t)ell < pattern_length && pattern[ell - 1] == pattern[ell]) {
        ++ell;
    }
    if ((size_t)ell == pattern_length) ell = 0;

    int64_t match_count = 0;
    int64_t sum_offsets = 0;
    int64_t xor_offsets = 0;
    if (text_length >= pattern_length) {
        int64_t i = ell;
        int64_t j = 0;
        int64_t k = 0;
        while ((size_t)j <= text_length - pattern_length) {
            while ((size_t)i < pattern_length
                   && pattern[i] == input[2 + (size_t)j + (size_t)i]) {
                ++i;
            }
            if ((size_t)i >= pattern_length) {
                while ((size_t)k < (size_t)ell
                       && pattern[k] == input[2 + (size_t)j + (size_t)k]) {
                    ++k;
                }
                if (k >= ell) {
                    ++match_count;
                    sum_offsets += j;
                    xor_offsets ^= j;
                }
            }

            j += i - kmp_next[i];
            if (i == ell) {
                if (k > 0) --k;
            } else if (kmp_next[i] <= ell) {
                k = kmp_next[i] > 0 ? kmp_next[i] : 0;
                i = ell;
            } else {
                k = ell;
                i = kmp_next[i];
            }
        }
    }

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets;
}
