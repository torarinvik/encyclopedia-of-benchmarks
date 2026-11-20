#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 128, MAX_PATTERN = 32, ALPHABET = 16, MAX_INPUT = 162, K = 4 };

static void factorize(const int64_t *x, int m, int *out_s, int *out_p1, int *out_q1)
{
    int s = 0, p1 = 1, q1 = 0;
    for (;;) {
        while (s + p1 + q1 < m && x[s + q1] == x[s + p1 + q1]) ++q1;
        if (p1 + q1 >= K * p1) {
            int p2 = q1, q2 = 0;
            for (;;) {
                while (p2 + q2 < K * p2 && s + p2 + q2 < m &&
                       x[s + q2] == x[s + p2 + q2]) ++q2;
                if (p2 + q2 == K * p2) {
                    for (;;) {
                        while (s + p1 + q1 < m && x[s + q1] == x[s + p1 + q1]) ++q1;
                        while (p1 + q1 >= K * p1) { s += p1; q1 -= p1; }
                        if (s + p1 + q1 == m) {
                            *out_s = s; *out_p1 = p1; *out_q1 = q1; return;
                        }
                        p1 += q1 / K + 1;
                        q1 = 0;
                        if (p1 >= p2) break;
                    }
                    break;
                }
                if (s + p2 + q2 == m) {
                    *out_s = s; *out_p1 = p1; *out_q1 = q1; return;
                }
                if (q2 == p1 + q1) { p2 += p1; q2 -= p1; }
                else { p2 += q2 / K + 1; q2 = 0; }
            }
        } else {
            if (s + p1 + q1 == m) {
                *out_s = s; *out_p1 = p1; *out_q1 = q1; return;
            }
            p1 += q1 / K + 1;
            q1 = 0;
        }
    }
}

int64_t galil_seiferas_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_INPUT) return -2;
    if (values[0] < 0 || values[0] > MAX_TEXT ||
        values[1] < 1 || values[1] > MAX_PATTERN) return -2;
    const int n = (int)values[0], m = (int)values[1];
    if (length != 2 + (size_t)n + (size_t)m) return -2;
    for (int i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] >= ALPHABET) return -2;
    if (m > n) return 0;
    const int64_t *text = values + 2;
    const int64_t *pattern = text + n;
    int s, p1, q1;
    factorize(pattern, m, &s, &p1, &q1);
    int p = 0, q = 0;
    int64_t matches = 0;
    while (p <= n - m) {
        while (s + q < m && pattern[s + q] == text[p + s + q]) ++q;
        if (q == m - s) {
            int i = 0;
            while (i < s && pattern[i] == text[p + i]) ++i;
            if (i == s) ++matches;
        }
        if (q == p1 + q1) { p += p1; q -= p1; }
        else { p += q / K + 1; q = 0; }
    }
    return matches;
}
