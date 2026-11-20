/* Clean-room LDFS+ / Rightmost-Neighbor path-cover profile. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_PARSEABLE = 18 };

static int label_compare(const uint8_t a[MAX_N], int a_len,
                         const uint8_t b[MAX_N], int b_len) {
    const int common = a_len < b_len ? a_len : b_len;
    for (int i = 0; i < common; ++i) {
        if (a[i] != b[i]) return a[i] > b[i] ? 1 : -1;
    }
    return (a_len > b_len) - (a_len < b_len);
}

int64_t cocomparability_ldfs_minimum_path_cover(const int64_t *input,
                                                 size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE) return -1;
    const int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_N || length != 1 + 2 * (size_t)n64) return -1;
    const int n = (int)n64;
    uint16_t adjacency[MAX_N] = {0};
    int order[MAX_N], rank[MAX_N], position[MAX_N];
    bool seen_order[MAX_N] = {false};
    const uint16_t full = (uint16_t)((1u << n) - 1u);
    for (int v = 0; v < n; ++v) {
        const int64_t row = input[1 + v];
        if (row < 0 || (uint64_t)row > full || (row & (INT64_C(1) << v))) return -1;
        adjacency[v] = (uint16_t)row;
    }
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v)
            if (((adjacency[u] >> v) & 1u) != ((adjacency[v] >> u) & 1u)) return -1;
    for (int i = 0; i < n; ++i) {
        const int64_t value = input[1 + n + i];
        if (value < 0 || value >= n || seen_order[value]) return -1;
        order[i] = (int)value;
        rank[value] = i;
        seen_order[value] = true;
    }
    for (int i = 0; i < n; ++i)
        for (int j = i + 1; j < n; ++j)
            for (int k = j + 1; k < n; ++k) {
                const int a = order[i], b = order[j], c = order[k];
                if (((adjacency[a] >> c) & 1u) &&
                    !(((adjacency[a] >> b) & 1u) || ((adjacency[b] >> c) & 1u))) return -1;
            }
    uint16_t reached = 1u;
    int queue[MAX_N], head = 0, tail = 0;
    queue[tail++] = 0;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) {
            const uint16_t bit = (uint16_t)(1u << v);
            if ((adjacency[u] & bit) && !(reached & bit)) {
                reached |= bit;
                queue[tail++] = v;
            }
        }
    }
    if (reached != full) return -1;

    uint8_t labels[MAX_N][MAX_N] = {{0}};
    int label_len[MAX_N] = {0}, ldfs[MAX_N];
    bool visited[MAX_N] = {false};
    for (int step = 1; step <= n; ++step) {
        int chosen = -1;
        for (int v = 0; v < n; ++v) if (!visited[v]) {
            if (chosen < 0 || label_compare(labels[v], label_len[v], labels[chosen], label_len[chosen]) > 0 ||
                (label_compare(labels[v], label_len[v], labels[chosen], label_len[chosen]) == 0 && rank[v] > rank[chosen]))
                chosen = v;
        }
        ldfs[step - 1] = chosen;
        visited[chosen] = true;
        for (int v = 0; v < n; ++v) if (!visited[v] && (adjacency[chosen] & (uint16_t)(1u << v))) {
            for (int i = label_len[v]; i > 0; --i) labels[v][i] = labels[v][i - 1];
            labels[v][0] = (uint8_t)step;
            ++label_len[v];
        }
    }
    for (int i = 0; i < n; ++i) position[ldfs[i]] = i;

    for (int v = 0; v < n; ++v) visited[v] = false;
    int paths = 0;
    for (;;) {
        int current = -1;
        for (int v = 0; v < n; ++v)
            if (!visited[v] && (current < 0 || position[v] > position[current])) current = v;
        if (current < 0) break;
        ++paths;
        visited[current] = true;
        for (;;) {
            int next = -1;
            for (int v = 0; v < n; ++v)
                if (!visited[v] && (adjacency[current] & (uint16_t)(1u << v)) &&
                    (next < 0 || position[v] > position[next])) next = v;
            if (next < 0) break;
            visited[next] = true;
            current = next;
        }
    }
    return paths;
}
