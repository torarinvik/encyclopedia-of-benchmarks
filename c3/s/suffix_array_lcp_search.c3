module suffix_array_lcp_search;

const int MAX_N = 32;
const int MAX_M = 16;
const int MAX_INPUT = 50;
const int MAX_OUTPUT = 264;

fn void put_i64(char* out, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { out[at + b] = (char)(bits & 255); bits >>= 8; }
}

fn int suffix_cmp(long* text, int a, int b, int n) {
    int k = 0;
    while (a + k < n && b + k < n) {
        if (text[a + k] < text[b + k]) return -1;
        if (text[a + k] > text[b + k]) return 1;
        k += 1;
    }
    if (a + k == n && b + k == n) return 0;
    return a + k == n ? -1 : 1;
}

fn int pattern_cmp(long* text, int start, int n, long* pattern, int m,
                   int offset, bool prefix_equal, int* matched_out) {
    int matched = offset;
    while (matched < m && start + matched < n && text[start + matched] == pattern[matched]) matched += 1;
    *matched_out = matched;
    if (matched == m) {
        if (prefix_equal || start + matched == n) return 0;
        return 1;
    }
    if (start + matched == n) return -1;
    return text[start + matched] < pattern[matched] ? -1 : 1;
}

fn void build_intervals(int n, int* lcp, int* left_q, int* right_q) {
    int lo_stack[2 * MAX_N];
    int hi_stack[2 * MAX_N];
    int top = 0;
    lo_stack[top] = 0; hi_stack[top] = n - 1; top += 1;
    while (top > 0) {
        top -= 1;
        int lo = lo_stack[top], hi = hi_stack[top];
        if (hi - lo < 2) continue;
        int mid = (lo + hi + 1) / 2;
        int q = n + 1;
        for (int k = lo; k < mid; k += 1) if (lcp[k] < q) q = lcp[k];
        left_q[lo * MAX_N + hi] = q;
        q = n + 1;
        for (int k = mid; k < hi; k += 1) if (lcp[k] < q) q = lcp[k];
        right_q[lo * MAX_N + hi] = q;
        if (hi - mid >= 2) { lo_stack[top] = mid; hi_stack[top] = hi; top += 1; }
        if (mid - lo >= 2) { lo_stack[top] = lo; hi_stack[top] = mid; top += 1; }
    }
}

fn int bound(long* text, int n, long* pattern, int m, int* suffix,
             int* left_q, int* right_q, bool prefix_equal) {
    int l = 0, r = 0;
    int first = pattern_cmp(text, suffix[0], n, pattern, m, 0, prefix_equal, &l);
    if (first > 0 || (!prefix_equal && first == 0)) return 0;
    int last = pattern_cmp(text, suffix[n - 1], n, pattern, m, 0, prefix_equal, &r);
    if (last < 0 || (prefix_equal && last == 0)) return n;
    int lo = 0, hi = n - 1;
    while (hi - lo > 1) {
        int mid = (lo + hi + 1) / 2;
        int cmp = 0, matched = 0;
        if (l == r) {
            cmp = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal, &matched);
            if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; }
            else { lo = mid; l = matched; }
        } else if (l > r) {
            int q = left_q[lo * MAX_N + hi];
            if (l < q) lo = mid;
            else if (l > q) { hi = mid; r = q; }
            else {
                cmp = pattern_cmp(text, suffix[mid], n, pattern, m, l, prefix_equal, &matched);
                if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; }
                else { lo = mid; l = matched; }
            }
        } else {
            int q = right_q[lo * MAX_N + hi];
            if (r < q) hi = mid;
            else if (r > q) { lo = mid; l = q; }
            else {
                cmp = pattern_cmp(text, suffix[mid], n, pattern, m, r, prefix_equal, &matched);
                if (cmp > 0 || (!prefix_equal && cmp == 0)) { hi = mid; r = matched; }
                else { lo = mid; l = matched; }
            }
        }
    }
    return hi;
}

fn long suffix_array_lcp_search(long* v, usz length, char* output, usz capacity)
    @export("suffix_array_lcp_search") {
    if (v == null || length < (usz)3 || length > (usz)MAX_INPUT) return -1;
    if (v[0] < 1 || v[0] > (long)MAX_N) return -1;
    int n = (int)v[0];
    if (length < (usz)(n + 2)) return -1;
    long m_value = v[n + 1];
    if (m_value < 1 || m_value > (long)MAX_M || length != (usz)(n + m_value + 2)) return -1;
    int m = (int)m_value;
    long[MAX_N] text = zeroed;
    long[MAX_M] pattern = zeroed;
    int[MAX_N] suffix = zeroed;
    int[MAX_N] lcp = zeroed;
    int[MAX_N * MAX_N] left_q = zeroed;
    int[MAX_N * MAX_N] right_q = zeroed;
    for (int i = 0; i < n; i += 1) {
        text[i] = v[1 + i];
        if (text[i] < 0 || text[i] > 127) return -1;
        suffix[i] = i;
    }
    for (int i = 0; i < m; i += 1) {
        pattern[i] = v[n + 2 + i];
        if (pattern[i] < 0 || pattern[i] > 127) return -1;
    }
    for (int i = 1; i < n; i += 1) {
        int key = suffix[i], j = i;
        while (j > 0 && suffix_cmp(&text[0], key, suffix[j - 1], n) < 0) {
            suffix[j] = suffix[j - 1]; j -= 1;
        }
        suffix[j] = key;
    }
    for (int i = 0; i + 1 < n; i += 1) {
        int a = suffix[i], b = suffix[i + 1], k = 0;
        while (a + k < n && b + k < n && text[a + k] == text[b + k]) k += 1;
        lcp[i] = k;
    }
    build_intervals(n, &lcp[0], &left_q[0], &right_q[0]);
    int first = bound(&text[0], n, &pattern[0], m, &suffix[0], &left_q[0], &right_q[0], false);
    int last = bound(&text[0], n, &pattern[0], m, &suffix[0], &left_q[0], &right_q[0], true);
    int count = last - first;
    usz bytes = 8 * (usz)(count + 1);
    if (output == null || capacity < bytes) return -2;
    char[MAX_OUTPUT] staged = zeroed;
    put_i64(&staged[0], 0, (long)count);
    for (int i = 0; i < count; i += 1) put_i64(&staged[0], 8 * (usz)(i + 1), (long)suffix[first + i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = staged[i];
    return (long)bytes;
}
