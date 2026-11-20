/* Clean-room DAG-to-bipartite-matching minimum path-cover profile. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 10, MAX_M = 45, MAX_VALID = 92, MAX_PARSEABLE = 93 };

static int augment(const uint16_t *adj, int n, uint16_t used, int left,
                   bool *seen, int *pair_right) {
    for (int right = 0; right < n; ++right) {
        const uint16_t bit = (uint16_t)(1u << right);
        if (!(adj[left] & bit) || (used & bit) || seen[right]) continue;
        seen[right] = true;
        const int mate = pair_right[right];
        if (mate < 0 || augment(adj, n, used, mate, seen, pair_right)) {
            pair_right[right] = left;
            return 1;
        }
    }
    return 0;
}

static int maximum_matching(const uint16_t *adj, int n, int first, uint16_t used) {
    int pair_right[MAX_N];
    for (int i = 0; i < n; ++i) pair_right[i] = -1;
    int size = 0;
    for (int left = first; left < n; ++left) {
        bool seen[MAX_N] = {false};
        size += augment(adj, n, used, left, seen, pair_right);
    }
    return size;
}

int64_t dag_minimum_path_cover(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    uint16_t adjacency[MAX_N] = {0};
    int indegree[MAX_N] = {0}, queue[MAX_N];
    for (int i = 0; i < m; ++i) {
        const int64_t u64 = input[2 + 2 * i], v64 = input[3 + 2 * i];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64) return -1;
        const int u = (int)u64, v = (int)v64;
        if (adjacency[u] & (uint16_t)(1u << v)) return -1;
        adjacency[u] |= (uint16_t)(1u << v);
        ++indegree[v];
    }
    int head = 0, tail = 0, removed = 0;
    for (int v = 0; v < n; ++v) if (indegree[v] == 0) queue[tail++] = v;
    while (head < tail) {
        const int u = queue[head++];
        ++removed;
        for (int v = 0; v < n; ++v) if (adjacency[u] & (uint16_t)(1u << v))
            if (--indegree[v] == 0) queue[tail++] = v;
    }
    if (removed != n) return -1;

    const int maximum = maximum_matching(adjacency, n, 0, 0);
    int successor[MAX_N], fixed = 0;
    uint16_t used = 0;
    for (int left = 0; left < n; ++left) {
        bool chosen = false;
        for (int right = 0; right <= n; ++right) {
            const bool matched = right < n;
            if (matched && (!(adjacency[left] & (uint16_t)(1u << right)) ||
                            (used & (uint16_t)(1u << right)))) continue;
            const uint16_t next_used = matched ? (uint16_t)(used | (uint16_t)(1u << right)) : used;
            if (fixed + (int)matched + maximum_matching(adjacency, n, left + 1, next_used) == maximum) {
                successor[left] = right;
                used = next_used;
                fixed += (int)matched;
                chosen = true;
                break;
            }
        }
        if (!chosen) return -1;
    }
    uint64_t packed = (uint64_t)(n - maximum) << 40;
    for (int v = 0; v < n; ++v) packed |= (uint64_t)successor[v] << (4 * v);
    return (int64_t)packed;
}
