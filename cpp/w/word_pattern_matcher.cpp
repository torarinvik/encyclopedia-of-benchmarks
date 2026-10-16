#include <stddef.h>
#include <stdint.h>

static int match(const int64_t *p, size_t pn, const int64_t *s, size_t sn,
                 size_t pi, size_t si, int64_t *start, size_t *length, int *used) {
    if (pi == pn || si == sn) return pi == pn && si == sn;
    int64_t ch = p[pi];
    if (used[ch]) {
        size_t n = length[ch];
        if (si + n > sn) return 0;
        for (size_t i = 0; i < n; ++i) if (s[si + i] != s[start[ch] + i]) return 0;
        return match(p, pn, s, sn, pi + 1, si + n, start, length, used);
    }
    for (size_t n = 1; si + n <= sn; ++n) {
        int duplicate = 0;
        for (int c = 32; c <= 126 && !duplicate; ++c) if (used[c] && length[c] == n) {
            size_t i = 0;
            while (i < n && s[start[c] + i] == s[si + i]) ++i;
            duplicate = i == n;
        }
        if (duplicate) continue;
        used[ch] = 1; start[ch] = si; length[ch] = n;
        if (match(p, pn, s, sn, pi + 1, si + n, start, length, used)) return 1;
        used[ch] = 0;
    }
    return 0;
}

extern "C" int64_t word_pattern_matcher(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    (void)output; (void)capacity;
    if (!input || length < 2) return -1;
    int64_t pn64 = input[0];
    if (pn64 < 0 || pn64 > 8 || length < (size_t)pn64 + 2) return -1;
    size_t pn = (size_t)pn64, at = pn + 1;
    int64_t sn64 = input[at++];
    if (sn64 < 0 || sn64 > 32 || length != at + (size_t)sn64) return -1;
    size_t sn = (size_t)sn64;
    for (size_t i = 0; i < pn; ++i) if (input[i + 1] < 32 || input[i + 1] > 126) return -1;
    for (size_t i = 0; i < sn; ++i) if (input[at + i] < 32 || input[at + i] > 126) return -1;
    int64_t starts[127] = {0}; size_t lengths[127] = {0}; int used[127] = {0};
    return match(input + 1, pn, input + at, sn, 0, 0, starts, lengths, used);
}
