module k_mismatch_longest_extension_table;

const usz MAX_N = 64;
const usz MAX_K = 4;
const usz MAX_INPUT = 67;
const usz MAX_OUTPUT = 320;
const usz MAX_LEVELS = 7;

fn bool pair_less(usz a, usz b, usz width, int* rank, usz n) {
    if (rank[a] != rank[b]) return rank[a] < rank[b];
    int ra = a + width < n ? rank[a + width] : -1;
    int rb = b + width < n ? rank[b + width] : -1;
    return ra < rb;
}

fn int lce(usz a, usz b, usz n, usz* inverse, int* sparse, usz* logs) {
    if (a >= n || b >= n) return 0;
    if (a == b) return (int)(n - a);
    usz left = inverse[a], right = inverse[b];
    if (left > right) { usz t = left; left = right; right = t; }
    left++;
    usz count = right - left + 1;
    usz level = logs[count], span = (usz)1 << level;
    int x = sparse[level * MAX_N + left], y = sparse[level * MAX_N + right - span + 1];
    return x < y ? x : y;
}

fn long k_mismatch_longest_extension_table(long* input, usz length, char* output, usz capacity)
        @export("k_mismatch_longest_extension_table") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long nv = input[0], kv = input[1];
    if (nv < 1 || nv > (long)MAX_N || kv < 0 || kv > (long)MAX_K) return -1;
    usz n = (usz)nv, budget = (usz)kv;
    if (length != n + 2) return -1;

    int[MAX_N] text = zeroed;
    usz[MAX_N] suffixes = zeroed, inverse = zeroed;
    int[MAX_N] rank = zeroed, next_rank = zeroed, lcp = zeroed;
    int[MAX_LEVELS * MAX_N] sparse = zeroed;
    usz[MAX_N + 1] logs = zeroed;
    char[MAX_OUTPUT] staged = zeroed;
    for (usz i = 0; i < n; i++) {
        long symbol = input[i + 2];
        if (symbol < 0 || symbol > 25) return -1;
        text[i] = (int)symbol;
        suffixes[i] = i;
        rank[i] = (int)symbol;
    }
    usz width = 1;
    while (width < n) {
        for (usz i = 1; i < n; i++) {
            usz key = suffixes[i], j = i;
            while (j > 0 && pair_less(key, suffixes[j - 1], width, &rank[0], n)) {
                suffixes[j] = suffixes[j - 1];
                j--;
            }
            suffixes[j] = key;
        }
        int classes = 0;
        next_rank[suffixes[0]] = 0;
        for (usz i = 1; i < n; i++) {
            usz a = suffixes[i - 1], b = suffixes[i];
            int a2 = a + width < n ? rank[a + width] : -1;
            int b2 = b + width < n ? rank[b + width] : -1;
            if (rank[a] != rank[b] || a2 != b2) classes++;
            next_rank[b] = classes;
        }
        for (usz i = 0; i < n; i++) rank[i] = next_rank[i];
        if ((usz)classes == n - 1 || width > n / 2) break;
        width *= 2;
    }
    for (usz i = 0; i < n; i++) inverse[suffixes[i]] = i;
    usz matched = 0;
    for (usz start = 0; start < n; start++) {
        usz order = inverse[start];
        if (order == 0) { matched = 0; continue; }
        usz other = suffixes[order - 1];
        while (start + matched < n && other + matched < n && text[start + matched] == text[other + matched]) matched++;
        lcp[order] = (int)matched;
        if (matched > 0) matched--;
    }
    for (usz i = 0; i < n; i++) sparse[i] = lcp[i];
    for (usz level = 1; level < MAX_LEVELS; level++) {
        usz span = (usz)1 << level, half = span / 2;
        for (usz i = 0; i + span <= n; i++) {
            int a = sparse[(level - 1) * MAX_N + i], b = sparse[(level - 1) * MAX_N + i + half];
            sparse[level * MAX_N + i] = a < b ? a : b;
        }
    }
    for (usz count = 2; count <= n; count++) logs[count] = logs[count / 2] + 1;
    usz written = 0;
    for (usz p = 0; p < n; p++) {
        usz limit = n - p;
        usz extension = (usz)lce(0, p, n, &inverse[0], &sparse[0], &logs[0]);
        if (extension > limit) extension = limit;
        staged[written++] = (char)extension;
        for (usz k = 1; k <= budget; k++) {
            if (extension < limit) {
                extension += 1 + (usz)lce(extension + 1, p + extension + 1, n, &inverse[0], &sparse[0], &logs[0]);
                if (extension > limit) extension = limit;
            }
            staged[written++] = (char)extension;
        }
    }
    if (written > MAX_OUTPUT) return -1;
    if (output == null || capacity < written) return -2;
    for (usz i = 0; i < written; i++) output[i] = staged[i];
    return (long)written;
}
