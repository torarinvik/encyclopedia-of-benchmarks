#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 31, MAX_INPUT = 99, MAX_OUTPUT = 256 };

static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[offset + b] = (uint8_t)(bits & 255); bits >>= 8; }
}

int64_t technology_mapping_minimum_area_tree_cover(const int64_t *v, size_t length,
                                                    uint8_t *output, size_t capacity) {
    if (v == NULL || length < 9 || length > MAX_INPUT || v[0] < 1 || v[0] > MAX_N) return -1;
    const size_t n = (size_t)v[0];
    if (length != 6 + 3 * n) return -1;
    int64_t cost[5];
    for (size_t p = 0; p < 5; ++p) {
        cost[p] = v[1 + p];
        if (cost[p] != -1 && (cost[p] < 1 || cost[p] > 1000000)) return -1;
    }
    int kind[MAX_N], left[MAX_N], right[MAX_N], parents[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        const size_t at = 6 + 3 * i;
        const int64_t k = v[at], l = v[at + 1], r = v[at + 2];
        if (k < 0 || k > 2) return -1;
        kind[i] = (int)k; left[i] = (int)l; right[i] = (int)r;
        if (k == 0) { if (l != -1 || r != -1) return -1; }
        else if (k == 1) {
            if (l <= (int64_t)i || l >= (int64_t)n || r != -1) return -1;
            ++parents[(size_t)l];
        } else {
            if (l <= (int64_t)i || l >= (int64_t)n || r <= (int64_t)i || r >= (int64_t)n || l == r) return -1;
            ++parents[(size_t)l]; ++parents[(size_t)r];
        }
    }
    if (parents[0] != 0) return -1;
    for (size_t i = 1; i < n; ++i) if (parents[i] != 1) return -1;
    const int64_t inf = INT64_MAX / 4;
    int64_t best[MAX_N]; int choice[MAX_N];
    for (size_t i = n; i-- > 0;) {
        best[i] = inf; choice[i] = -1;
        if (kind[i] == 0) { best[i] = 0; continue; }
#define CANDIDATE(pattern, expression) do { if (cost[pattern] >= 0) { int64_t candidate = (expression); if (candidate < inf && candidate < best[i]) { best[i] = candidate; choice[i] = (pattern); } } } while (0)
        if (kind[i] == 1) CANDIDATE(0, cost[0] + best[left[i]]);
        else {
            CANDIDATE(1, cost[1] + best[left[i]] + best[right[i]]);
            if (kind[left[i]] == 1) CANDIDATE(2, cost[2] + best[left[left[i]]] + best[right[i]]);
            if (kind[right[i]] == 1) CANDIDATE(3, cost[3] + best[left[i]] + best[left[right[i]]]);
            if (kind[left[i]] == 1 && kind[right[i]] == 1)
                CANDIDATE(4, cost[4] + best[left[left[i]]] + best[left[right[i]]]);
        }
#undef CANDIDATE
    }
    if (best[0] == inf) return -1;
    int mapping[MAX_N];
    for (size_t i = 0; i < n; ++i) mapping[i] = kind[i] == 0 ? -1 : -3;
    int stack[2 * MAX_N], top = 0;
    if (kind[0] != 0) stack[top++] = 0;
    while (top > 0) {
        const int node = stack[--top], pattern = choice[node];
        mapping[node] = pattern;
        if (pattern == 0) stack[top++] = left[node];
        else if (pattern == 1) { stack[top++] = left[node]; stack[top++] = right[node]; }
        else if (pattern == 2) { mapping[left[node]] = -2; stack[top++] = left[left[node]]; stack[top++] = right[node]; }
        else if (pattern == 3) { mapping[right[node]] = -2; stack[top++] = left[node]; stack[top++] = left[right[node]]; }
        else { mapping[left[node]] = -2; mapping[right[node]] = -2; stack[top++] = left[left[node]]; stack[top++] = left[right[node]]; }
    }
    const size_t bytes = 8 * (n + 1);
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT]; put_i64(staged, 0, best[0]);
    for (size_t i = 0; i < n; ++i) put_i64(staged, 8 * (i + 1), mapping[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
