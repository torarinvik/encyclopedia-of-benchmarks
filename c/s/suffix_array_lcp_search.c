#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_PATTERN = 16, MAX_INPUT = 50, MAX_OUTPUT = 264 };
static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255); bits >>= 8; }
}
static int suffix_compare(const int64_t text[MAX_N], int a, int b, int n) {
    int offset = 0;
    while (a + offset < n && b + offset < n) {
        if (text[a + offset] < text[b + offset]) return -1;
        if (text[a + offset] > text[b + offset]) return 1;
        ++offset;
    }
    if (a + offset == n && b + offset == n) return 0;
    return a + offset == n ? -1 : 1;
}
static int compare_pattern(const int64_t text[MAX_N], int start, int n,
                           const int64_t *pattern, int m, int offset, int prefix_equal, int *matched_out) {
    int matched = offset;
    while (matched < m && start + matched < n && text[start + matched] == pattern[matched]) ++matched;
    *matched_out = matched;
    if (matched == m) {
        if (prefix_equal || start + matched == n) return 0;
        return 1;
    }
    if (start + matched == n) return -1;
    return text[start + matched] < pattern[matched] ? -1 : 1;
}
static void build_intervals(int n, const int lcp[MAX_N], int left_q[MAX_N][MAX_N], int right_q[MAX_N][MAX_N]) {
    int lo_stack[2 * MAX_N], hi_stack[2 * MAX_N], top = 0;
    lo_stack[top] = 0; hi_stack[top++] = n - 1;
    while (top > 0) {
        const int lo = lo_stack[--top], hi = hi_stack[top];
        if (hi - lo < 2) continue;
        const int mid = (lo + hi + 1) / 2;
        int q = n + 1;
        for (int k = lo; k < mid; ++k) if (lcp[k] < q) q = lcp[k];
        left_q[lo][hi] = q;
        q = n + 1;
        for (int k = mid; k < hi; ++k) if (lcp[k] < q) q = lcp[k];
        right_q[lo][hi] = q;
        if (hi - mid >= 2) { lo_stack[top] = mid; hi_stack[top++] = hi; }
        if (mid - lo >= 2) { lo_stack[top] = lo; hi_stack[top++] = mid; }
    }
}
static int bound(const int64_t text[MAX_N], int n, const int64_t *pattern, int m,
                 const int suffix[MAX_N], const int left_q[MAX_N][MAX_N], const int right_q[MAX_N][MAX_N], int prefix_equal) {
    int l = 0, r = 0;
    const int cmp_first = compare_pattern(text, suffix[0], n, pattern, m, 0, prefix_equal, &l);
    if (cmp_first > 0 || (!prefix_equal && cmp_first == 0)) return 0;
    const int cmp_last = compare_pattern(text, suffix[n - 1], n, pattern, m, 0, prefix_equal, &r);
    if (cmp_last < 0 || (prefix_equal && cmp_last == 0)) return n;
    int lo = 0, hi = n - 1;
    while (hi - lo > 1) {
        const int mid = (lo + hi + 1) / 2;
        int cmp = 0, matched = 0;
        if (l == r) {
            cmp = compare_pattern(text, suffix[mid], n, pattern, m, l, prefix_equal, &matched);
            if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; }
            else { lo = mid; l = matched; }
        } else if (l > r) {
            const int q = left_q[lo][hi];
            if (l < q) lo = mid;
            else if (l > q) { hi = mid; r = q; }
            else {
                cmp = compare_pattern(text, suffix[mid], n, pattern, m, l, prefix_equal, &matched);
                if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; }
                else { lo = mid; l = matched; }
            }
        } else {
            const int q = right_q[lo][hi];
            if (r < q) hi = mid;
            else if (r > q) { lo = mid; l = q; }
            else {
                cmp = compare_pattern(text, suffix[mid], n, pattern, m, r, prefix_equal, &matched);
                if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; }
                else { lo = mid; l = matched; }
            }
        }
    }
    return hi;
}

int64_t suffix_array_lcp_search(const int64_t *v, size_t length, uint8_t *output, size_t capacity) {
    if (!v || length < 3 || length > MAX_INPUT || v[0] < 1 || v[0] > MAX_N) return -1;
    const int n = (int)v[0]; if (length < (size_t)(n + 2)) return -1;
    const int m = (int)v[n + 1]; if (m < 1 || m > MAX_PATTERN || length != (size_t)(n + m + 2)) return -1;
    int64_t text[MAX_N] = {0}, pattern[MAX_PATTERN] = {0};
    for (int i = 0; i < n; ++i) { text[i] = v[1 + i]; if (text[i] < 0 || text[i] > 127) return -1; }
    for (int i = 0; i < m; ++i) { pattern[i] = v[n + 2 + i]; if (pattern[i] < 0 || pattern[i] > 127) return -1; }
    int suffix[MAX_N]; for (int i = 0; i < n; ++i) suffix[i] = i;
    for (int i = 1; i < n; ++i) { const int key = suffix[i]; int j = i; while (j > 0 && suffix_compare(text, key, suffix[j - 1], n) < 0) { suffix[j] = suffix[j - 1]; --j; } suffix[j] = key; }
    int lcp[MAX_N] = {0};
    for (int i = 0; i + 1 < n; ++i) { int a = suffix[i], b = suffix[i + 1], k = 0; while (a + k < n && b + k < n && text[a + k] == text[b + k]) ++k; lcp[i] = k; }
    int left_q[MAX_N][MAX_N] = {{0}}, right_q[MAX_N][MAX_N] = {{0}};
    build_intervals(n, lcp, left_q, right_q);
    const int first = bound(text, n, pattern, m, suffix, left_q, right_q, 0);
    const int last = bound(text, n, pattern, m, suffix, left_q, right_q, 1);
    const int count = last - first; const size_t bytes = 8 * (size_t)(count + 1);
    if (!output || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT]; put_i64(staged, 0, count);
    for (int i = 0; i < count; ++i) put_i64(staged, 8 * (size_t)(i + 1), suffix[first + i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
