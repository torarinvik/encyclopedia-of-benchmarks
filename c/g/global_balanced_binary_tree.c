#include <stddef.h>
#include <stdint.h>

#define GBST_MAX_N 64
#define GBST_MAX_PARSEABLE_LENGTH 65

static int build_interval(int lo, int hi, const int *path, const int *prefix,
                          int *gbst_parent, int *left_child, int *right_child,
                          int *local_size) {
    const int total_weight = prefix[hi] - prefix[lo];
    int low = lo, high = hi;
    while (high - low > 1) {
        const int middle = (low + high) / 2;
        if (2 * (prefix[middle] - prefix[lo]) <= total_weight)
            low = middle;
        else
            high = middle;
    }

    const int pivot = low;
    const int node = path[pivot];
    local_size[node] = hi - lo;
    if (lo < pivot) {
        const int child = build_interval(lo, pivot, path, prefix, gbst_parent,
                                         left_child, right_child, local_size);
        left_child[node] = child;
        gbst_parent[child] = node;
    }
    if (pivot + 1 < hi) {
        const int child = build_interval(pivot + 1, hi, path, prefix, gbst_parent,
                                         left_child, right_child, local_size);
        right_child[node] = child;
        gbst_parent[child] = node;
    }
    return node;
}

int64_t global_balanced_binary_tree(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > GBST_MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > GBST_MAX_N || length != (size_t)n_value) return -1;
    const int n = (int)n_value;

    int parent[GBST_MAX_N];
    int subtree_size[GBST_MAX_N];
    int heavy_child[GBST_MAX_N];
    int gbst_parent[GBST_MAX_N];
    int left_child[GBST_MAX_N];
    int right_child[GBST_MAX_N];
    int local_size[GBST_MAX_N];
    int path[GBST_MAX_N];
    int prefix[GBST_MAX_N + 1];

    for (int vertex = 0; vertex < n; ++vertex) {
        parent[vertex] = -1;
        subtree_size[vertex] = 1;
        heavy_child[vertex] = -1;
        gbst_parent[vertex] = -1;
        left_child[vertex] = -1;
        right_child[vertex] = -1;
        local_size[vertex] = 0;
    }
    for (int vertex = 1; vertex < n; ++vertex) {
        const int64_t p = input[vertex];
        if (p < 0 || p >= vertex) return -1;
        parent[vertex] = (int)p;
    }

    for (int vertex = n - 1; vertex > 0; --vertex)
        subtree_size[parent[vertex]] += subtree_size[vertex];
    for (int vertex = 1; vertex < n; ++vertex) {
        const int p = parent[vertex];
        const int current = heavy_child[p];
        if (current < 0 || subtree_size[vertex] > subtree_size[current])
            heavy_child[p] = vertex;
    }

    for (int head = 0; head < n; ++head) {
        if (head > 0 && heavy_child[parent[head]] == head) continue;
        int path_length = 0;
        int vertex = head;
        prefix[0] = 0;
        while (vertex >= 0) {
            const int child = heavy_child[vertex];
            const int weight = subtree_size[vertex] -
                               (child >= 0 ? subtree_size[child] : 0);
            path[path_length] = vertex;
            prefix[path_length + 1] = prefix[path_length] + weight;
            ++path_length;
            vertex = child;
        }
        const int root = build_interval(0, path_length, path, prefix, gbst_parent,
                                        left_child, right_child, local_size);
        gbst_parent[root] = head == 0 ? -1 : parent[head];
    }

    int64_t checksum = 0;
    for (int vertex = 0; vertex < n; ++vertex) {
        const int64_t record = (int64_t)(gbst_parent[vertex] + 1)
            + INT64_C(65) * (left_child[vertex] + 1)
            + INT64_C(4225) * (right_child[vertex] + 1)
            + INT64_C(274625) * local_size[vertex];
        checksum += (int64_t)(vertex + 1) * record;
    }
    return checksum;
}
