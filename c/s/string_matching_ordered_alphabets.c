#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 4096, MAX_PATTERN = 128, MAX_INPUT = 4227 };

static void advance_maximal_suffix(const int64_t *segment, int length,
                                   int *left, int *right, int *offset, int *period) {
    while (*right + *offset < length) {
        const int64_t a = segment[*left + *offset];
        const int64_t b = segment[*right + *offset];
        if (a == b) {
            if (*offset == *period) {
                *right += *period;
                *offset = 1;
            } else {
                ++*offset;
            }
        } else if (a > b) {
            *right += *offset;
            *offset = 1;
            *period = *right - *left;
        } else {
            *left = *right;
            ++*right;
            *offset = 1;
            *period = 1;
        }
    }
}

static int prefix_repeats(const int64_t *segment, int shift, int last_index) {
    for (int q = 0; q <= last_index; ++q)
        if (segment[q] != segment[shift + q]) return 0;
    return 1;
}

int64_t string_matching_ordered_alphabets(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN) return -1;
    const int n = (int)n64, m = (int)m64;
    if (length != (size_t)(2 + n + m)) return -1;
    const size_t pattern_start = 2 + (size_t)n;
    for (int q = 0; q < n; ++q)
        if (input[2 + q] < 0 || input[2 + q] > 3) return -1;
    for (int q = 0; q < m; ++q)
        if (input[pattern_start + (size_t)q] < 0 || input[pattern_start + (size_t)q] > 3) return -1;
    if (n < m) return 0;

    int alignment = 0, matched = 0;
    int suffix_left = -1, suffix_right = 0, suffix_offset = 1, period = 1;
    int64_t count = 0, offset_sum = 0, offset_xor = 0;
    while (alignment <= n - m) {
        while (alignment + matched < n && matched < m &&
               input[pattern_start + (size_t)matched] ==
                   input[2 + (size_t)(alignment + matched)]) ++matched;
        if (matched == 0) {
            ++alignment;
            suffix_left = -1;
            suffix_right = 0;
            suffix_offset = period = 1;
            continue;
        }
        if (matched == m) {
            ++count;
            offset_sum += alignment;
            offset_xor ^= alignment;
            if (alignment == n - m) break;
        }

        const int64_t *segment = input + 2 + (size_t)alignment;
        advance_maximal_suffix(segment, matched + 1,
                               &suffix_left, &suffix_right, &suffix_offset, &period);
        const int reusable = suffix_left < 0 ||
            (suffix_left < period && prefix_repeats(segment, period, suffix_left));
        if (reusable) {
            alignment += period;
            matched -= period;
            if (matched < 0) matched = 0;
            if (suffix_right - suffix_left > period) {
                suffix_right -= period;
            } else {
                suffix_left = -1;
                suffix_right = 0;
                suffix_offset = period = 1;
            }
        } else {
            const int conservative = matched - suffix_left - 1 < suffix_right + 1
                ? matched - suffix_left - 1 : suffix_right + 1;
            const int certified = suffix_left + 1 > conservative ? suffix_left + 1 : conservative;
            alignment += certified + 1;
            matched = 0;
            suffix_left = -1;
            suffix_right = 0;
            suffix_offset = period = 1;
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
