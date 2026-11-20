#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 4096, MAX_PATTERN = 128, MAX_INPUT = 4227 };

int64_t reverse_colussi_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN) return -1;
    const int n = (int)n64, m = (int)m64;
    if (length != (size_t)(2 + n + m)) return -1;
    uint8_t text[MAX_TEXT], pattern[MAX_PATTERN];
    for (int q = 0; q < n; ++q) {
        const int64_t value = input[2 + q];
        if (value < 0 || value > 3) return -1;
        text[q] = (uint8_t)value;
    }
    for (int q = 0; q < m; ++q) {
        const int64_t value = input[2 + n + q];
        if (value < 0 || value > 3) return -1;
        pattern[q] = (uint8_t)value;
    }
    if (n < m) return 0;

    int hmin[MAX_PATTERN + 1], kmin[MAX_PATTERN] = {0};
    int rmin[MAX_PATTERN], order[MAX_PATTERN], good_suffix[MAX_PATTERN + 1] = {0};
    int bad_character[4][MAX_PATTERN + 1];
    for (int shift = 1; shift <= m; ++shift) {
        int last_mismatch = shift - 1;
        for (int pos = shift; pos < m; ++pos)
            if (pattern[pos] != pattern[pos - shift]) last_mismatch = pos;
        hmin[shift] = last_mismatch;
    }
    for (int shift = m; shift >= 1; --shift)
        if (hmin[shift] != m - 1) kmin[hmin[shift]] = shift;

    int next_boundary = m;
    for (int end = m - 1; end >= 0; --end) {
        if (hmin[end + 1] == end) next_boundary = end + 1;
        rmin[end] = next_boundary;
    }

    order[0] = m - 1;
    int cursor = 0;
    for (int shift = 1; shift <= m; ++shift) {
        const int end = hmin[shift];
        if (end != m - 1 && kmin[end] == shift) {
            order[++cursor] = end;
            good_suffix[cursor] = shift;
        }
    }
    cursor = m - 1;
    for (int end = m - 2; end >= 0; --end) {
        if (kmin[end] == 0) {
            order[cursor] = end;
            good_suffix[cursor] = rmin[end];
            --cursor;
        }
    }
    good_suffix[m] = rmin[0];

    for (int symbol = 0; symbol < 4; ++symbol) {
        for (int prior_shift = 1; prior_shift <= m; ++prior_shift) {
            const int boundary = m - prior_shift - 1;
            for (int shift = 1; shift <= m; ++shift) {
                if (shift < m && pattern[m - shift - 1] != symbol) continue;
                if (shift <= boundary &&
                    pattern[m - shift - prior_shift - 1] != pattern[boundary]) continue;
                bad_character[symbol][prior_shift] = shift;
                break;
            }
        }
    }

    int64_t count = 0, offset_sum = 0, offset_xor = 0;
    int start = 0, shift_state = m;
    const int last_start = n - m;
    while (start <= last_start) {
        while (start <= last_start && pattern[m - 1] != text[start + m - 1]) {
            shift_state = bad_character[text[start + m - 1]][shift_state];
            start += shift_state;
        }
        if (start > last_start) break;
        int index = 1;
        while (index < m && pattern[order[index]] == text[start + order[index]]) ++index;
        if (index == m) {
            ++count;
            offset_sum += start;
            offset_xor ^= start;
        }
        shift_state = good_suffix[index];
        start += shift_state;
    }
    return (int64_t)(((uint64_t)count << 36) |
                     ((uint64_t)offset_sum << 12) | (uint64_t)offset_xor);
}
