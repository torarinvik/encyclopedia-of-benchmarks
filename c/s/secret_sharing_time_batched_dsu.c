#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 20, MAX_PARSEABLE_LENGTH = 64 };

static int find_root(int parent[MAX_N], int value) {
    while (parent[value] != value) {
        parent[value] = parent[parent[value]];
        value = parent[value];
    }
    return value;
}

static void join_sets(int parent[MAX_N], int size[MAX_N], int left, int right) {
    int a = find_root(parent, left), b = find_root(parent, right);
    if (a == b) return;
    if (size[a] < size[b]) { int swap = a; a = b; b = swap; }
    parent[b] = a;
    size[a] += size[b];
}

int64_t secret_sharing_time_batched_dsu(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0], first_value = input[1], m_value = input[2];
    if (n_value < 2 || n_value > MAX_N || first_value < 1 || first_value >= n_value
        || m_value < 0 || m_value > MAX_M) return -1;
    const int n = (int)n_value, first = (int)first_value, m = (int)m_value;
    if (length != (size_t)(3 + 3 * m)) return -1;
    int parent[MAX_N], size[MAX_N];
    for (int i = 0; i < n; ++i) { parent[i] = i; size[i] = 1; }
    for (int i = 0; i < m; ++i) {
        const int64_t u = input[3 + 3 * i], v = input[4 + 3 * i], time = input[5 + 3 * i];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || time < 1 || time > 20) return -1;
    }
    join_sets(parent, size, 0, first);
    for (int time = 1; time <= 20; ++time) {
        int touched[MAX_N] = {0};
        for (int i = 0; i < m; ++i) {
            const int u = (int)input[3 + 3 * i], v = (int)input[4 + 3 * i];
            if (input[5 + 3 * i] == time) {
                join_sets(parent, size, u, v);
                touched[u] = touched[v] = 1;
            }
        }
        const int known_root = find_root(parent, 0);
        for (int node = 0; node < n; ++node) {
            if (touched[node] && find_root(parent, node) != known_root) {
                parent[node] = node;
                size[node] = 1;
            }
        }
    }
    const int known_root = find_root(parent, 0);
    int64_t result = 0;
    for (int node = 0; node < n; ++node)
        if (find_root(parent, node) == known_root) result |= INT64_C(1) << node;
    return result;
}
