#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_INPUT = 25 };

static int intersects(int64_t *s, int64_t *e, int a, int b) {
    return s[a] <= e[b] && s[b] <= e[a];
}

int64_t minimal_dominating_sets_interval(const int64_t *input, size_t length,
                                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_N || length != 1 + 2 * (size_t)n64) return -1;
    int n = (int)n64;
    int64_t s[MAX_N], e[MAX_N], min_end = INT64_MAX, max_start = INT64_MIN;
    for (int i = 0; i < n; ++i) {
        s[i] = input[1 + 2 * i]; e[i] = input[2 + 2 * i];
        if (s[i] < -100 || s[i] > 100 || e[i] < -100 || e[i] > 100 || s[i] >= e[i]) return -1;
        if (i > 0 && s[i - 1] >= s[i]) return -1;
        if (e[i] < min_end) min_end = e[i];
        if (s[i] > max_start) max_start = s[i];
        for (int j = 0; j < i; ++j)
            if (s[i] == s[j] || s[i] == e[j] || e[i] == s[j] || e[i] == e[j]) return -1;
    }
    if (output == NULL || capacity < 8) return -2;

    int has_next[MAX_N] = {0};
    int64_t ncs[MAX_N] = {0}, nce[MAX_N] = {0};
    int64_t p_single[MAX_N];
    for (int i = 0; i < n; ++i) {
        p_single[i] = INT64_MAX;
        for (int z = 0; z < n; ++z) {
            if (intersects(s, e, i, z) && e[z] < p_single[i]) p_single[i] = e[z];
            if (s[z] > e[i]) {
                if (!has_next[i] || s[z] < ncs[i]) ncs[i] = s[z];
                if (!has_next[i] || e[z] < nce[i]) nce[i] = e[z];
                has_next[i] = 1;
            }
        }
    }
    int valid[MAX_N][MAX_N] = {{0}};
    int64_t p_pair[MAX_N][MAX_N];
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j) {
        p_pair[i][j] = INT64_MAX;
        for (int z = 0; z < n; ++z)
            if (intersects(s, e, j, z) && !intersects(s, e, i, z) && e[z] < p_pair[i][j])
                p_pair[i][j] = e[z];
        valid[i][j] = has_next[i] && p_single[i] < s[j] && s[j] <= nce[i] && e[j] >= ncs[i];
    }
    int64_t ways[MAX_N][MAX_N] = {{0}};
    for (int j = 1; j < n; ++j) for (int i = 0; i < j; ++i) {
        if (!valid[i][j]) continue;
        if (s[i] <= min_end) ++ways[i][j];
        for (int k = j + 1; k < n; ++k)
            if (valid[j][k] && p_pair[i][j] < s[k] && s[k] <= nce[j])
                ways[j][k] += ways[i][j];
    }
    int64_t count = 0;
    for (int i = 0; i < n; ++i) if (s[i] <= min_end && e[i] >= max_start) ++count;
    for (int i = 0; i < n; ++i) for (int j = i + 1; j < n; ++j)
        if (e[j] >= max_start) count += ways[i][j];
    uint64_t bits = (uint64_t)count;
    for (unsigned b = 0; b < 8; ++b) output[b] = (uint8_t)(bits >> (8 * b));
    return 8;
}
