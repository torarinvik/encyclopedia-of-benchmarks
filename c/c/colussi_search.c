#include <stddef.h>
#include <stdint.h>

#define COLUSSI_MAX_TEXT_LENGTH 4096
#define COLUSSI_MAX_PATTERN_LENGTH 128
#define COLUSSI_MAX_PARSEABLE_LENGTH 4227
#define COLUSSI_TABLE_SIZE (COLUSSI_MAX_PATTERN_LENGTH + 1)

static int64_t colussi_preprocess(const int64_t *pattern, size_t m,
                                 int64_t *h, int64_t *next,
                                 int64_t *shift) {
    int64_t hmax[COLUSSI_TABLE_SIZE] = {0};
    int64_t kmin[COLUSSI_TABLE_SIZE] = {0};
    int64_t nhd0[COLUSSI_TABLE_SIZE] = {0};
    int64_t rmin[COLUSSI_TABLE_SIZE] = {0};
    int64_t i = 1;
    int64_t k = 1;

    while ((size_t)k <= m) {
        while (pattern[i] == pattern[i - k]) ++i;
        hmax[k] = i;
        int64_t q = k + 1;
        while (hmax[q - k] + k < i) {
            hmax[q] = hmax[q - k] + k;
            ++q;
        }
        k = q;
        if (k == i + 1) i = k;
    }

    for (size_t index = 0; index <= m; ++index) kmin[index] = 0;
    for (i = (int64_t)m; i >= 1; --i) {
        if ((size_t)hmax[i] < m) kmin[hmax[i]] = i;
    }

    int64_t r = (int64_t)m;
    for (i = (int64_t)m - 1; i >= 0; --i) {
        if ((size_t)hmax[i + 1] == m) r = i + 1;
        rmin[i] = kmin[i] == 0 ? r : 0;
    }

    int64_t s = -1;
    r = (int64_t)m;
    for (i = 0; (size_t)i < m; ++i) {
        if (kmin[i] == 0) h[--r] = i;
        else h[++s] = i;
    }
    const int64_t nd = s;

    for (i = 0; i <= nd; ++i) shift[i] = kmin[h[i]];
    for (i = nd + 1; (size_t)i < m; ++i) shift[i] = rmin[h[i]];
    shift[m] = rmin[0];

    s = 0;
    for (i = 0; (size_t)i < m; ++i) {
        nhd0[i] = s;
        if (kmin[i] > 0) ++s;
    }

    for (i = 0; i <= nd; ++i) next[i] = nhd0[h[i] - kmin[h[i]]];
    for (i = nd + 1; (size_t)i < m; ++i)
        next[i] = nhd0[(int64_t)m - rmin[h[i]]];
    next[m] = nhd0[(int64_t)m - rmin[h[m - 1]]];
    return nd;
}

int64_t colussi_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > COLUSSI_MAX_PARSEABLE_LENGTH) {
        return -1;
    }

    const int64_t text_length_value = input[0];
    const int64_t pattern_length_value = input[1];
    if (text_length_value < 0 || text_length_value > COLUSSI_MAX_TEXT_LENGTH
        || pattern_length_value < 1
        || pattern_length_value > COLUSSI_MAX_PATTERN_LENGTH) {
        return -1;
    }
    const size_t n = (size_t)text_length_value;
    const size_t m = (size_t)pattern_length_value;
    if (length != 2 + n + m) return -1;

    const size_t pattern_start = 2 + n;
    int64_t pattern[COLUSSI_TABLE_SIZE] = {0};
    for (size_t index = 0; index < n; ++index) {
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;
    }
    for (size_t index = 0; index < m; ++index) {
        const int64_t symbol = input[pattern_start + index];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[index] = symbol;
    }
    pattern[m] = 4;

    int64_t h[COLUSSI_TABLE_SIZE] = {0};
    int64_t next[COLUSSI_TABLE_SIZE] = {0};
    int64_t shift[COLUSSI_TABLE_SIZE] = {0};
    const int64_t nd = colussi_preprocess(pattern, m, h, next, shift);

    int64_t match_count = 0;
    int64_t sum_offsets = 0;
    int64_t xor_offsets = 0;
    if (n >= m) {
        int64_t i = 0;
        int64_t j = 0;
        int64_t last = -1;
        while ((size_t)j <= n - m) {
            while ((size_t)i < m && last < j + h[i]
                   && pattern[h[i]] == input[2 + (size_t)j + (size_t)h[i]]) {
                ++i;
            }
            if ((size_t)i >= m) {
                ++match_count;
                sum_offsets += j;
                xor_offsets ^= j;
                i = (int64_t)m;
            } else if (last >= j + h[i]) {
                ++match_count;
                sum_offsets += j;
                xor_offsets ^= j;
                i = (int64_t)m;
            }
            if (i > nd) last = j + (int64_t)m - 1;
            j += shift[i];
            i = next[i];
        }
    }

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets;
}
