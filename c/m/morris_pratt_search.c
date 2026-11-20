#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 4096, MAX_PATTERN = 128, MAX_INPUT = 4227 };

int64_t morris_pratt_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    if (length != 2 + n + m) return -1;
    const size_t pattern_start = 2 + n;
    for (size_t q = 0; q < n + m; ++q)
        if (input[2 + q] < 0 || input[2 + q] > 3) return -1;

    int64_t mp_next[MAX_PATTERN + 1];
    mp_next[0] = -1;
    for (size_t index = 0; index < m; ++index) {
        int64_t border = mp_next[index];
        while (border >= 0 && input[pattern_start + index] != input[pattern_start + (size_t)border])
            border = mp_next[(size_t)border];
        mp_next[index + 1] = border + 1;
    }

    int64_t matched = 0, count = 0, offset_sum = 0, offset_xor = 0;
    for (size_t text_index = 0; text_index < n; ++text_index) {
        while (matched >= 0 && input[pattern_start + (size_t)matched] != input[2 + text_index])
            matched = mp_next[(size_t)matched];
        ++matched;
        if ((size_t)matched == m) {
            const int64_t start = (int64_t)(text_index + 1) - matched;
            ++count;
            offset_sum += start;
            offset_xor ^= start;
            matched = mp_next[m];
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
