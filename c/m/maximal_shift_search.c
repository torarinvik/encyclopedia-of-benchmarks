#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 4096, MAX_PATTERN = 128, MAX_INPUT = 4227, ALPHABET = 4 };

static int match_shift(const uint8_t *pattern, int m, const int *order_loc,
                       const int *order_symbol, int prefix_length, int shift) {
    while (shift < m) {
        int order_index = prefix_length - 1;
        while (order_index >= 0) {
            const int pattern_index = order_loc[order_index] - shift;
            if (pattern_index >= 0 && order_symbol[order_index] != pattern[pattern_index]) break;
            --order_index;
        }
        if (order_index < 0) break;
        ++shift;
    }
    return shift;
}

int64_t maximal_shift_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN) return -1;
    const int n = (int)n64, m = (int)m64;
    if (length != (size_t)(2 + n + m)) return -1;
    uint8_t text[MAX_TEXT], pattern[MAX_PATTERN];
    for (int q = 0; q < n; ++q) {
        const int64_t value = input[2 + q];
        if (value < 0 || value >= ALPHABET) return -1;
        text[q] = (uint8_t)value;
    }
    for (int q = 0; q < m; ++q) {
        const int64_t value = input[2 + n + q];
        if (value < 0 || value >= ALPHABET) return -1;
        pattern[q] = (uint8_t)value;
    }
    if (n < m) return 0;

    int leading_shift[MAX_PATTERN];
    int order_loc[MAX_PATTERN + 1];
    int order_symbol[MAX_PATTERN + 1];
    int quick_shift[ALPHABET];
    int adapted_shift[MAX_PATTERN + 1] = {0};
    for (int i = 0; i < m; ++i) {
        int previous = i - 1;
        while (previous >= 0 && pattern[previous] != pattern[i]) --previous;
        leading_shift[i] = i - previous;
        int position = i;
        while (position > 0) {
            const int prior_loc = order_loc[position - 1];
            if (leading_shift[prior_loc] > leading_shift[i] ||
                (leading_shift[prior_loc] == leading_shift[i] && prior_loc > i)) break;
            order_loc[position] = prior_loc;
            --position;
        }
        order_loc[position] = i;
    }
    for (int i = 0; i < m; ++i) order_symbol[i] = pattern[order_loc[i]];
    order_loc[m] = m;
    order_symbol[m] = -1;

    for (int symbol = 0; symbol < ALPHABET; ++symbol) quick_shift[symbol] = m + 1;
    for (int i = 0; i < m; ++i) quick_shift[pattern[i]] = m - i;

    int shift = 1;
    adapted_shift[0] = 1;
    for (int prefix_length = 1; prefix_length <= m; ++prefix_length) {
        shift = match_shift(pattern, m, order_loc, order_symbol, prefix_length, shift);
        adapted_shift[prefix_length] = shift;
    }
    for (int prefix_length = 0; prefix_length <= m; ++prefix_length) {
        shift = adapted_shift[prefix_length];
        while (shift < m) {
            const int pattern_index = order_loc[prefix_length] - shift;
            if (pattern_index < 0 || order_symbol[prefix_length] != pattern[pattern_index]) break;
            ++shift;
            shift = match_shift(pattern, m, order_loc, order_symbol, prefix_length, shift);
        }
        adapted_shift[prefix_length] = shift;
    }

    int64_t count = 0, offset_sum = 0, offset_xor = 0;
    int start = 0;
    while (start <= n - m) {
        int compared = 0;
        while (compared < m &&
               order_symbol[compared] == text[start + order_loc[compared]]) ++compared;
        if (compared == m) {
            ++count;
            offset_sum += start;
            offset_xor ^= start;
        }
        const int lookahead = start + m;
        if (lookahead >= n) break;
        const int advance = adapted_shift[compared] > quick_shift[text[lookahead]]
                          ? adapted_shift[compared] : quick_shift[text[lookahead]];
        start += advance;
    }
    return (int64_t)(((uint64_t)count << 36) |
                     ((uint64_t)offset_sum << 12) | (uint64_t)offset_xor);
}
