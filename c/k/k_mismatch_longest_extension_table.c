#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_K = 4, MAX_INPUT = 67, MAX_OUTPUT = 320, MAX_LEVELS = 7 };

static int pair_less(int a, int b, int width, const int rank[MAX_N], int n) {
    if (rank[a] != rank[b]) return rank[a] < rank[b];
    const int ra = a + width < n ? rank[a + width] : -1;
    const int rb = b + width < n ? rank[b + width] : -1;
    return ra < rb;
}

static int lce(int a, int b, int n, const int inverse[MAX_N],
               const int sparse[MAX_LEVELS][MAX_N], const int logs[MAX_N + 1]) {
    if (a >= n || b >= n) return 0;
    if (a == b) return n - a;
    int left = inverse[a], right = inverse[b];
    if (left > right) { const int temporary = left; left = right; right = temporary; }
    ++left;
    const int length = right - left + 1;
    const int level = logs[length], span = 1 << level;
    const int x = sparse[level][left], y = sparse[level][right - span + 1];
    return x < y ? x : y;
}

int64_t k_mismatch_longest_extension_table(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0], k_value = input[1];
    if (n_value < 1 || n_value > MAX_N || k_value < 0 || k_value > MAX_K) return -1;
    const int n = (int)n_value, budget = (int)k_value;
    if (length != (size_t)n + 2) return -1;

    int text[MAX_N] = {0};
    int suffixes[MAX_N] = {0}, rank[MAX_N] = {0}, next_rank[MAX_N] = {0};
    int inverse[MAX_N] = {0}, lcp[MAX_N] = {0};
    int sparse[MAX_LEVELS][MAX_N] = {{0}}, logs[MAX_N + 1] = {0};
    uint8_t staged[MAX_OUTPUT] = {0};
    for (int i = 0; i < n; ++i) {
        if (input[i + 2] < 0 || input[i + 2] > 25) return -1;
        text[i] = (int)input[i + 2];
        suffixes[i] = i;
        rank[i] = text[i];
    }

    for (int width = 1; width < n; width *= 2) {
        for (int i = 1; i < n; ++i) {
            const int key = suffixes[i];
            int j = i;
            while (j > 0 && pair_less(key, suffixes[j - 1], width, rank, n)) {
                suffixes[j] = suffixes[j - 1];
                --j;
            }
            suffixes[j] = key;
        }
        int classes = 0;
        next_rank[suffixes[0]] = 0;
        for (int i = 1; i < n; ++i) {
            const int a = suffixes[i - 1], b = suffixes[i];
            if (rank[a] != rank[b]
                || (a + width < n ? rank[a + width] : -1)
                    != (b + width < n ? rank[b + width] : -1)) ++classes;
            next_rank[b] = classes;
        }
        for (int i = 0; i < n; ++i) rank[i] = next_rank[i];
        if (classes == n - 1 || width > n / 2) break;
    }

    for (int i = 0; i < n; ++i) inverse[suffixes[i]] = i;
    int matched = 0;
    for (int start = 0; start < n; ++start) {
        const int order = inverse[start];
        if (order == 0) { matched = 0; continue; }
        const int other = suffixes[order - 1];
        while (start + matched < n && other + matched < n
               && text[start + matched] == text[other + matched]) ++matched;
        lcp[order] = matched;
        if (matched > 0) --matched;
    }
    for (int i = 0; i < n; ++i) sparse[0][i] = lcp[i];
    for (int level = 1; level < MAX_LEVELS; ++level) {
        const int span = 1 << level, half = span >> 1;
        for (int i = 0; i + span <= n; ++i) {
            const int a = sparse[level - 1][i], b = sparse[level - 1][i + half];
            sparse[level][i] = a < b ? a : b;
        }
    }
    for (int length_value = 2; length_value <= n; ++length_value)
        logs[length_value] = logs[length_value / 2] + 1;

    int out = 0;
    for (int p = 0; p < n; ++p) {
        const int limit = n - p;
        int extension = lce(0, p, n, inverse, sparse, logs);
        if (extension > limit) extension = limit;
        staged[out++] = (uint8_t)extension;
        for (int k = 1; k <= budget; ++k) {
            if (extension < limit) {
                extension += 1 + lce(extension + 1, p + extension + 1, n, inverse, sparse, logs);
                if (extension > limit) extension = limit;
            }
            staged[out++] = (uint8_t)extension;
        }
    }
    if (out > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < (size_t)out) return -2;
    for (int i = 0; i < out; ++i) output[i] = staged[i];
    return out;
}
