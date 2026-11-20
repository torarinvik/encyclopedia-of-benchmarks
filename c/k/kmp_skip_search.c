#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 4096, MAX_PATTERN = 128, MAX_INPUT = 4227 };

static int advance_sample(const uint8_t *text, int n, int m,
                          const int last[4], int *sample, int *position) {
    do {
        *sample += m;
    } while (*sample < n && last[text[*sample]] < 0);
    if (*sample >= n) return 0;
    *position = last[text[*sample]];
    return 1;
}

int64_t kmp_skip_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_TEXT || m64 < 1 || m64 > MAX_PATTERN) return -1;
    const int n = (int)n64, m = (int)m64;
    if (length != (size_t)(2 + n + m)) return -1;

    uint8_t text[MAX_TEXT], pattern[MAX_PATTERN];
    for (int q = 0; q < n; ++q) {
        const int64_t symbol = input[2 + q];
        if (symbol < 0 || symbol > 3) return -1;
        text[q] = (uint8_t)symbol;
    }
    for (int q = 0; q < m; ++q) {
        const int64_t symbol = input[2 + n + q];
        if (symbol < 0 || symbol > 3) return -1;
        pattern[q] = (uint8_t)symbol;
    }
    if (n < m) return 0;

    int mp_next[MAX_PATTERN + 1], kmp_next[MAX_PATTERN + 1];
    int q = 0, border = -1;
    mp_next[0] = -1;
    while (q < m) {
        while (border >= 0 && pattern[q] != pattern[border]) border = mp_next[border];
        ++q;
        ++border;
        mp_next[q] = border;
    }
    q = 0;
    border = -1;
    kmp_next[0] = -1;
    while (q < m) {
        while (border >= 0 && pattern[q] != pattern[border]) border = kmp_next[border];
        ++q;
        ++border;
        if (q < m && pattern[q] == pattern[border]) kmp_next[q] = kmp_next[border];
        else kmp_next[q] = border;
    }

    int last[4] = {-1, -1, -1, -1};
    int previous[MAX_PATTERN];
    for (int q = 0; q < m; ++q) {
        previous[q] = last[pattern[q]];
        last[pattern[q]] = q;
    }

    int sample = -1, i = -1;
    if (!advance_sample(text, n, m, last, &sample, &i)) return 0;
    int start = sample - i;
    int wall = 0;
    const int period = m - kmp_next[m];
    int64_t count = 0, offset_sum = 0, offset_xor = 0;
    while (start <= n - m) {
        if (start > wall) wall = start;
        int k = wall - start;
        while (k < m && pattern[k] == text[start + k]) ++k;
        wall = start + k;
        if (k == m) {
            ++count;
            offset_sum += start;
            offset_xor ^= start;
            i -= period;
        } else {
            i = previous[i];
        }
        if (i < 0 && !advance_sample(text, n, m, last, &sample, &i)) break;

        int kmp_start = start + k - kmp_next[k];
        k = kmp_next[k];
        start = sample - i;
        while (start < kmp_start || (kmp_start < start && start < wall)) {
            if (start < kmp_start) {
                i = previous[i];
                if (i < 0 && !advance_sample(text, n, m, last, &sample, &i))
                    goto finished;
                start = sample - i;
            } else {
                kmp_start += k - mp_next[k];
                k = mp_next[k];
            }
        }
    }

finished:
    return (int64_t)(((uint64_t)count << 36) |
                     ((uint64_t)offset_sum << 12) | (uint64_t)offset_xor);
}
