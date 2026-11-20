#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 256, MAX_PATTERN = 16, ALPHABET = 16, MAX_INPUT = 274 };

int64_t zhu_takaoka_search(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_INPUT) return -2;
    if (values[0] < 0 || values[0] > MAX_TEXT ||
        values[1] < 2 || values[1] > MAX_PATTERN) return -2;
    const size_t n = (size_t)values[0], m = (size_t)values[1];
    if (length != 2 + n + m) return -2;
    for (size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] >= ALPHABET) return -2;
    if (m > n) return -1;

    const size_t p = 2 + n;
    size_t pair_shift[ALPHABET][ALPHABET];
    for (size_t a = 0; a < ALPHABET; ++a)
        for (size_t b = 0; b < ALPHABET; ++b)
            pair_shift[a][b] = m;
    for (size_t a = 0; a < ALPHABET; ++a)
        pair_shift[a][(size_t)values[p]] = m - 1;
    for (size_t i = 1; i + 1 < m; ++i)
        pair_shift[(size_t)values[p + i - 1]][(size_t)values[p + i]] = m - 1 - i;

    size_t good_suffix[MAX_PATTERN];
    for (size_t mismatch = 0; mismatch < m; ++mismatch) {
        good_suffix[mismatch] = m;
        for (size_t shift = 1; shift <= m; ++shift) {
            const size_t first_known = mismatch + 1 > shift ? mismatch + 1 : shift;
            size_t position = first_known;
            while (position < m && values[p + position] == values[p + position - shift])
                ++position;
            if (position < m) continue;
            if (mismatch + 1 < m && shift <= mismatch &&
                values[p + mismatch - shift] == values[p + mismatch])
                continue;
            good_suffix[mismatch] = shift;
            break;
        }
    }

    size_t start = 0;
    while (start <= n - m) {
        size_t mismatch = m;
        while (mismatch > 0 && values[p + mismatch - 1] == values[2 + start + mismatch - 1])
            --mismatch;
        if (mismatch == 0) return (int64_t)start;
        --mismatch;
        const size_t first = (size_t)values[2 + start + m - 2];
        const size_t second = (size_t)values[2 + start + m - 1];
        const size_t pair = pair_shift[first][second];
        start += good_suffix[mismatch] > pair ? good_suffix[mismatch] : pair;
    }
    return -1;
}
