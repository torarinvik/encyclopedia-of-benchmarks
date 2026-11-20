#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_Q = 32, MAX_PARSEABLE_LENGTH = 99 };

static int find_root(int *parent, int vertex) {
    while (parent[vertex] >= 0) {
        int ancestor = parent[vertex];
        if (parent[ancestor] >= 0) parent[vertex] = parent[ancestor];
        vertex = ancestor;
    }
    return vertex;
}

static int unite_roots(int *parent, int *left, int *right, int root_a, int root_b) {
    if (parent[root_a] > parent[root_b]) {
        int temporary = root_a; root_a = root_b; root_b = temporary;
    }
    parent[root_a] += parent[root_b];
    parent[root_b] = root_a;
    if (left[root_b] < left[root_a]) left[root_a] = left[root_b];
    if (right[root_b] > right[root_a]) right[root_a] = right[root_b];
    return root_a;
}

int64_t range_union_find(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_LENGTH) return -1;
    int64_t n_value = values[0], q_value = values[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q ||
        length != 2 + 3 * (size_t)q_value) return -1;
    int n = (int)n_value, q = (int)q_value;
    for (int operation = 0; operation < q; ++operation) {
        size_t offset = 2 + 3 * (size_t)operation;
        int64_t opcode = values[offset], first = values[offset + 1], second = values[offset + 2];
        if (opcode == 0) {
            if (first < 0 || first > second || second > n) return -1;
        } else if (opcode == 1) {
            if (first < 0 || first >= n || second < 0 || second >= n) return -1;
        } else if (opcode == 2) {
            if (first < 0 || first >= n || second != 0) return -1;
        } else return -1;
    }

    int parent[MAX_N], left[MAX_N], right[MAX_N];
    for (int vertex = 0; vertex < n; ++vertex) {
        parent[vertex] = -1;
        left[vertex] = vertex;
        right[vertex] = vertex + 1;
    }
    int components = n;
    int64_t total = 0;
    for (int operation = 0; operation < q; ++operation) {
        size_t offset = 2 + 3 * (size_t)operation;
        int opcode = (int)values[offset];
        int first = (int)values[offset + 1], second = (int)values[offset + 2];
        int observed;
        if (opcode == 0) {
            if (first < second) {
                int root = find_root(parent, first);
                int next = right[root];
                while (next < second) {
                    int next_root = find_root(parent, next);
                    if (root == next_root) break;
                    root = unite_roots(parent, left, right, root, next_root);
                    --components;
                    next = right[root];
                }
            }
            observed = components;
        } else if (opcode == 1) {
            observed = find_root(parent, first) == find_root(parent, second);
        } else {
            observed = -parent[find_root(parent, first)];
        }
        total += (int64_t)(operation + 1) * observed;
    }
    return total;
}
