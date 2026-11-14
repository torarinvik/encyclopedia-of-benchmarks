#include <stddef.h>
#include <stdint.h>

int64_t backward_oracle_match(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || values[0] < 0 || values[0] > 4096 ||
        values[1] < 0 || values[1] > 63) return -2;
    size_t n = (size_t)values[0], m = (size_t)values[1];
    if (length != 2 + n + m) return -2;
    for (size_t i = 2; i < length; ++i)
        if (values[i] < 97 || values[i] > 122) return -2;
    if (m == 0) return 0;
    if (m > n) return -1;

    int next[64][26], suffix[64];
    for (size_t i = 0; i <= m; ++i) {
        suffix[i] = -1;
        for (size_t c = 0; c < 26; ++c) next[i][c] = -1;
    }
    for (size_t i = 0; i < m; ++i) {
        size_t letter = (size_t)(values[2 + n + m - 1 - i] - 97);
        next[i][letter] = (int)i + 1;
        int k = suffix[i];
        while (k >= 0 && next[k][letter] < 0) {
            next[k][letter] = (int)i + 1;
            k = suffix[k];
        }
        suffix[i + 1] = k < 0 ? 0 : next[k][letter];
    }
    size_t start = 0;
    while (start <= n - m) {
        int state = 0;
        size_t remaining = m, shift = m;
        while (remaining > 0) {
            --remaining;
            state = next[state][(size_t)(values[2 + start + remaining] - 97)];
            if (state < 0) { shift = remaining + 1; break; }
            if (remaining == 0) return (int64_t)start;
        }
        start += shift;
    }
    return -1;
}
