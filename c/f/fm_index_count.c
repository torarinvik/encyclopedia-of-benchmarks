#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 32, MAX_PATTERN = 8, MAX_INPUT = 42, ALPHABET = 5 };

static int suffix_less(const int64_t *s, size_t n, size_t a, size_t b) {
    while (a < n && b < n) {
        if (s[a] != s[b]) return s[a] < s[b];
        ++a; ++b;
    }
    return a == n && b != n;
}

int64_t fm_index_count(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t n0 = input[0];
    if (n0 < 1 || n0 > MAX_TEXT || length < (size_t)n0 + 3) return -1;
    size_t n = (size_t)n0, m_at = n + 1;
    int64_t m0 = input[m_at];
    if (m0 < 1 || m0 > MAX_PATTERN || length != m_at + 1 + (size_t)m0) return -1;
    size_t m = (size_t)m0, total = n + 1;
    int64_t text[MAX_TEXT], pattern[MAX_PATTERN], s[MAX_TEXT + 1];
    for (size_t i = 0; i < n; ++i) {
        if (input[1 + i] < 1 || input[1 + i] > 4) return -1;
        text[i] = input[1 + i]; s[i] = text[i];
    }
    for (size_t i = 0; i < m; ++i) {
        if (input[m_at + 1 + i] < 1 || input[m_at + 1 + i] > 4) return -1;
        pattern[i] = input[m_at + 1 + i];
    }
    s[n] = 0;
    if (output == NULL || capacity < 8) return -2;

    size_t sa[MAX_TEXT + 1];
    for (size_t i = 0; i < total; ++i) sa[i] = i;
    for (size_t i = 1; i < total; ++i) {
        size_t key = sa[i], j = i;
        while (j > 0 && suffix_less(s, total, key, sa[j - 1])) {
            sa[j] = sa[j - 1]; --j;
        }
        sa[j] = key;
    }
    int64_t bwt[MAX_TEXT + 1]; size_t freq[ALPHABET] = {0};
    for (size_t i = 0; i < total; ++i) {
        bwt[i] = s[(sa[i] + total - 1) % total];
        ++freq[(size_t)bwt[i]];
    }
    size_t cumulative[ALPHABET], sum = 0;
    for (size_t c = 0; c < ALPHABET; ++c) { cumulative[c] = sum; sum += freq[c]; }
    size_t left = 0, right = total;
    for (size_t k = m; k > 0; --k) {
        size_t c = (size_t)pattern[k - 1], rank_left = 0, rank_right = 0;
        for (size_t i = 0; i < left; ++i) if ((size_t)bwt[i] == c) ++rank_left;
        for (size_t i = 0; i < right; ++i) if ((size_t)bwt[i] == c) ++rank_right;
        left = cumulative[c] + rank_left; right = cumulative[c] + rank_right;
        if (left == right) break;
    }
    uint64_t count = (uint64_t)(right - left);
    for (size_t i = 0; i < 8; ++i) output[i] = (uint8_t)(count >> (8 * i));
    return 8;
}
