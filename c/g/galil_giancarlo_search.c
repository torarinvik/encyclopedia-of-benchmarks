#include <stddef.h>
#include <stdint.h>

#define GG_MAX_TEXT 4096
#define GG_MAX_PATTERN 128
#define GG_MAX_INPUT (2 + GG_MAX_TEXT + GG_MAX_PATTERN)
#define GG_TABLES (GG_MAX_PATTERN + 2)

static int64_t gg_preprocess(const int64_t *pattern, size_t m,
                             int64_t *order, int64_t *next, int64_t *shift) {
    int64_t hmax[GG_TABLES] = {0}, kmin[GG_TABLES] = {0};
    int64_t nohole_prefix[GG_TABLES] = {0}, rmin[GG_TABLES] = {0};
    int64_t i = 1, k = 1;
    while ((size_t)k <= m) {
        while (pattern[i] == pattern[i-k]) ++i;
        hmax[k] = i;
        int64_t q = k + 1;
        while (hmax[q-k] + k < i) { hmax[q] = hmax[q-k] + k; ++q; }
        k = q;
        if (k == i + 1) i = k;
    }
    for (i = (int64_t)m; i >= 1; --i) if ((size_t)hmax[i] < m) kmin[hmax[i]] = i;
    int64_t r = (int64_t)m;
    for (i = (int64_t)m - 1; i >= 0; --i) {
        if ((size_t)hmax[i+1] == m) r = i + 1;
        if (kmin[i] == 0) rmin[i] = r;
    }
    int64_t split = -1;
    r = (int64_t)m;
    for (i = 0; (size_t)i < m; ++i) {
        if (kmin[i] == 0) order[--r] = i;
        else order[++split] = i;
    }
    const int64_t nohole_end = split;
    for (i = 0; i <= nohole_end; ++i) shift[i] = kmin[order[i]];
    for (i = nohole_end + 1; (size_t)i < m; ++i) shift[i] = rmin[order[i]];
    shift[m] = rmin[0];
    int64_t count = 0;
    for (i = 0; (size_t)i < m; ++i) {
        nohole_prefix[i] = count;
        if (kmin[i] > 0) ++count;
    }
    for (i = 0; i <= nohole_end; ++i) next[i] = nohole_prefix[order[i] - kmin[order[i]]];
    for (i = nohole_end + 1; (size_t)i < m; ++i)
        next[i] = nohole_prefix[(int64_t)m - rmin[order[i]]];
    next[m] = nohole_prefix[(int64_t)m - rmin[order[m-1]]];
    return nohole_end;
}

static int64_t gg_search_valid(const int64_t *text, size_t n,
                               const int64_t *pattern, size_t m) {
    size_t ell = 0;
    while (ell + 1 < m && pattern[ell+1] == pattern[0]) ++ell;
    int64_t matches = 0, offset_sum = 0, offset_xor = 0;
    if (ell == m - 1) {
        size_t run = 0;
        for (size_t position = 0; position < n; ++position) {
            run = text[position] == pattern[0] ? run + 1 : 0;
            if (run >= m) {
                int64_t start = (int64_t)(position + 1 - m);
                ++matches; offset_sum += start; offset_xor ^= start;
            }
        }
        return (matches << 36) | (offset_sum << 12) | offset_xor;
    }

    int64_t order[GG_TABLES] = {0}, next[GG_TABLES] = {0}, shift[GG_TABLES] = {0};
    const int64_t nohole_end = gg_preprocess(pattern, m, order, next, shift);
    if (n < m) return 0;
    int64_t i = 0, j = 0, last = -1;
    int heavy = 0;
    while ((size_t)j <= n - m) {
        if (heavy && i == 0) {
            int64_t k = last - j + 1;
            while ((size_t)(j + k) < n && pattern[0] == text[j+k]) ++k;
            if ((size_t)k <= ell || (size_t)(j+k) >= n || pattern[ell+1] != text[j+k]) {
                i = 0;
                j += k + 1;
                last = j - 1;
            } else {
                i = 1;
                last = j + k;
                j = last - ((int64_t)ell + 1);
            }
        } else {
            while ((size_t)i < m && last < j + order[i] &&
                   pattern[order[i]] == text[j + order[i]]) ++i;
            if ((size_t)i >= m || last >= j + order[i]) {
                ++matches; offset_sum += j; offset_xor ^= j;
                i = (int64_t)m;
            }
            if (i > nohole_end) last = j + (int64_t)m - 1;
            j += shift[i];
            i = next[i];
        }
        heavy = j <= last;
    }
    return (matches << 36) | (offset_sum << 12) | offset_xor;
}

int64_t galil_giancarlo_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > GG_MAX_INPUT + 1) return -1;
    int64_t n_value=input[0], m_value=input[1];
    if (n_value < 0 || n_value > GG_MAX_TEXT || m_value < 1 || m_value > GG_MAX_PATTERN) return -1;
    size_t n=(size_t)n_value, m=(size_t)m_value;
    if (length != 2+n+m) return -1;
    int64_t text[GG_MAX_TEXT] = {0};
    int64_t pattern[GG_TABLES] = {0};
    for (size_t i=0;i<n;++i) { if (input[2+i] < 0 || input[2+i] > 3) return -1; text[i]=input[2+i]; }
    for (size_t i=0;i<m;++i) { if (input[2+n+i] < 0 || input[2+n+i] > 3) return -1; pattern[i]=input[2+n+i]; }
    pattern[m]=4;
    return gg_search_valid(text,n,pattern,m);
}
