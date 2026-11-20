#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64

static size_t find_successor(int64_t *parent, size_t node) {
    size_t root = node;
    while ((size_t)parent[root] != root) root = (size_t)parent[root];
    while ((size_t)parent[node] != node) {
        const size_t next = (size_t)parent[node];
        parent[node] = (int64_t)root;
        node = next;
    }
    return root;
}

int64_t offline_range_paint_successor_dsu(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 195) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + 3 * q) return -1;
    int64_t left[MAX_Q], right[MAX_Q], color[MAX_Q];
    for (size_t j = 0; j < q; ++j) {
        left[j] = input[2 + 3 * j]; right[j] = input[3 + 3 * j]; color[j] = input[4 + 3 * j];
        if (left[j] < 0 || left[j] > right[j] || right[j] >= n_value || color[j] < -1000 || color[j] > 1000) return -1;
    }
    int64_t parent[MAX_N + 1], final_color[MAX_N] = {0};
    for (size_t i = 0; i <= n; ++i) parent[i] = (int64_t)i;
    for (size_t j = q; j > 0; --j) {
        const size_t operation = j - 1;
        size_t cell = find_successor(parent, (size_t)left[operation]);
        while (cell <= (size_t)right[operation]) {
            final_color[cell] = color[operation];
            parent[cell] = (int64_t)find_successor(parent, cell + 1);
            cell = find_successor(parent, cell);
        }
    }
    int64_t checksum = 0;
    for (size_t i = 0; i < n; ++i) checksum += (int64_t)(i + 1) * (final_color[i] + 1001);
    return checksum;
}
