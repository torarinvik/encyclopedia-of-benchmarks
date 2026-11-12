#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64
#define MAX_LEVELS 7
#define MAX_INPUT_VALUES (2 + 2 * (MAX_N - 1) + 3 * MAX_Q)

static size_t find_root(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static size_t lift(const size_t ancestors[MAX_N][MAX_LEVELS], size_t vertex,
                   size_t distance) {
    for (size_t bit = 0; bit < MAX_LEVELS; ++bit)
        if ((distance >> bit) & 1U) vertex = ancestors[vertex][bit];
    return vertex;
}

static size_t lowest_common_ancestor(const size_t ancestors[MAX_N][MAX_LEVELS],
                                     const size_t depth[MAX_N], size_t left,
                                     size_t right) {
    if (depth[left] < depth[right]) {
        const size_t temporary = left;
        left = right;
        right = temporary;
    }
    left = lift(ancestors, left, depth[left] - depth[right]);
    if (left == right) return left;
    for (size_t level = MAX_LEVELS; level > 0; --level) {
        const size_t bit = level - 1;
        if (ancestors[left][bit] != ancestors[right][bit]) {
            left = ancestors[left][bit];
            right = ancestors[right][bit];
        }
    }
    return ancestors[left][0];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t jump_on_tree(const int64_t *input, size_t length, uint8_t *output,
                     size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 2 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    const size_t query_start = 2 + 2 * (n - 1);
    if (length != query_start + 3 * q) return -1;

    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    size_t dsu_parent[MAX_N], dsu_size[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const size_t offset = 2 + 2 * edge;
        const int64_t left_value = input[offset], right_value = input[offset + 1];
        if (left_value < 0 || left_value >= n_value || right_value < 0 ||
            right_value >= n_value || left_value == right_value) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        size_t root_left = find_root(dsu_parent, left);
        size_t root_right = find_root(dsu_parent, right);
        if (root_left == root_right) return -1;
        if (dsu_size[root_left] < dsu_size[root_right]) {
            const size_t temporary = root_left;
            root_left = root_right;
            root_right = temporary;
        }
        dsu_parent[root_right] = root_left;
        dsu_size[root_left] += dsu_size[root_right];
        adjacent[left][right] = adjacent[right][left] = 1;
    }

    size_t ancestors[MAX_N][MAX_LEVELS] = {{0}}, depth[MAX_N] = {0};
    uint8_t visited[MAX_N] = {0};
    size_t stack[MAX_N], top = 0;
    stack[top++] = 0;
    visited[0] = 1;
    while (top > 0) {
        const size_t vertex = stack[--top];
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacent[vertex][neighbor] || visited[neighbor]) continue;
            visited[neighbor] = 1;
            ancestors[neighbor][0] = vertex;
            depth[neighbor] = depth[vertex] + 1;
            stack[top++] = neighbor;
        }
    }
    for (size_t level = 1; level < MAX_LEVELS; ++level)
        for (size_t vertex = 0; vertex < n; ++vertex)
            ancestors[vertex][level] = ancestors[ancestors[vertex][level - 1]][level - 1];

    int64_t answers[MAX_Q];
    for (size_t query = 0; query < q; ++query) {
        const size_t offset = query_start + 3 * query;
        const int64_t start_value = input[offset], target_value = input[offset + 1];
        const int64_t index_value = input[offset + 2];
        if (start_value < 0 || start_value >= n_value || target_value < 0 ||
            target_value >= n_value || index_value < 0 || index_value >= n_value) return -1;
        const size_t start = (size_t)start_value, target = (size_t)target_value;
        const size_t index = (size_t)index_value;
        const size_t common = lowest_common_ancestor(ancestors, depth, start, target);
        const size_t upward = depth[start] - depth[common];
        const size_t path_length = upward + depth[target] - depth[common];
        if (index > path_length) {
            answers[query] = -1;
        } else if (index <= upward) {
            answers[query] = (int64_t)lift(ancestors, start, index);
        } else {
            answers[query] = (int64_t)lift(ancestors, target, path_length - index);
        }
    }

    const size_t required = 8 * q;
    if (output == NULL || capacity < required) return -2;
    for (size_t query = 0; query < q; ++query)
        store_i64_le(output, 8 * query, answers[query]);
    return (int64_t)required;
}
