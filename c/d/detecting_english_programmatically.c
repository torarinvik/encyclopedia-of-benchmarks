#include <stddef.h>
#include <stdint.h>

#define MAX_WORDS 8
#define MAX_WORD 12
#define MAX_MESSAGE 64

int64_t detecting_english_programmatically(const int64_t *a, size_t n) {
    if (!a || n < 1 || n > 2 + MAX_WORDS * (MAX_WORD + 1) + MAX_MESSAGE) return -1;
    size_t p = 0;
    int64_t count = a[p++];
    if (count < 0 || count > MAX_WORDS) return -1;
    size_t starts[MAX_WORDS], lengths[MAX_WORDS];
    for (int64_t w = 0; w < count; ++w) {
        if (p >= n) return -1;
        int64_t len = a[p++];
        if (len < 1 || len > MAX_WORD) return -1;
        if (p + (size_t)len > n) return -1;
        starts[w] = p; lengths[w] = (size_t)len;
        for (size_t j = 0; j < (size_t)len; ++j)
            if (a[p+j] < 65 || a[p+j] > 90) return -1;
        if (w) {
            int cmp = 0; size_t k = 0;
            while (k < lengths[w-1] && k < lengths[w] && a[starts[w-1]+k] == a[p+k]) ++k;
            if (k < lengths[w-1] && k < lengths[w]) cmp = a[starts[w-1]+k] < a[p+k] ? -1 : 1;
            else if (lengths[w-1] != lengths[w]) cmp = lengths[w-1] < lengths[w] ? -1 : 1;
            if (cmp >= 0) return -1;
        }
        p += (size_t)len;
    }
    if (p >= n) return -1;
    int64_t m = a[p++];
    if (m < 1 || m > MAX_MESSAGE || p + (size_t)m + 2 != n) return -1;
    size_t ms = p;
    for (size_t i = ms; i < ms + (size_t)m; ++i) if (a[i] < 0 || a[i] > 127) return -1;
    p += (size_t)m;
    int64_t wp = a[p++], lp = a[p++];
    if (wp < 0 || wp > 100 || lp < 0 || lp > 100) return -1;
    size_t retained = 0, tokens = 0, hits = 0, i = 0, token_len = 0;
    int64_t token[MAX_MESSAGE];
    while (i <= (size_t)m) {
        int64_t c = i < (size_t)m ? a[ms+i] : 32;
        int letter = (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
        int ws = c == 9 || c == 10 || c == 32;
        if (i < (size_t)m && (letter || ws)) ++retained;
        if (letter) { token[token_len++] = c >= 97 ? c - 32 : c; ++i; continue; }
        if (!ws) { ++i; continue; }
        if (token_len == 0) { ++i; continue; }
        ++tokens;
        for (int64_t w = 0; w < count; ++w) {
            if (lengths[w] != token_len) continue;
            size_t k = 0; while (k < token_len && a[starts[w]+k] == token[k]) ++k;
            if (k == token_len) { ++hits; break; }
        }
        token_len = 0; ++i;
    }
    if (tokens == 0) return -1;
    return hits * 100 >= wp * (int64_t)tokens && retained * 100 >= lp * m;
}
