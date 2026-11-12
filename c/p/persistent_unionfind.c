#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64
#define MAX_INPUT_VALUES (2 + 4 * MAX_Q)

static size_t find_root(const size_t *parent, size_t item) {
    while (parent[item] != item) item = parent[item];
    return item;
}

static void visit_version(size_t node,
    const int64_t *kind, const int64_t *u, const int64_t *v,
    const int64_t *first_child, const int64_t *next_sibling,
    size_t *parent, size_t *set_size, int64_t *answer,
    int64_t *history_child, int64_t *history_root, int64_t *history_size,
    size_t *history_count) {
    const size_t saved_history = *history_count;
    if (node != 0) {
        const size_t operation = node - 1;
        if (kind[operation] == 0) {
            size_t root_u = find_root(parent, (size_t)u[operation]);
            size_t root_v = find_root(parent, (size_t)v[operation]);
            if (root_u == root_v) {
                history_child[*history_count] = -1;
                history_root[*history_count] = -1;
                history_size[*history_count] = 0;
            } else {
                if (set_size[root_u] > set_size[root_v]) {
                    const size_t temporary = root_u;
                    root_u = root_v;
                    root_v = temporary;
                }
                history_child[*history_count] = (int64_t)root_u;
                history_root[*history_count] = (int64_t)root_v;
                history_size[*history_count] = (int64_t)set_size[root_v];
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
            }
            ++*history_count;
        } else {
            answer[node] = find_root(parent, (size_t)u[operation]) ==
                           find_root(parent, (size_t)v[operation]);
        }
    }
    for (int64_t child = first_child[node]; child >= 0; child = next_sibling[(size_t)child - 1])
        visit_version((size_t)child, kind, u, v, first_child, next_sibling,
                      parent, set_size, answer, history_child, history_root,
                      history_size, history_count);
    while (*history_count > saved_history) {
        --*history_count;
        const int64_t child = history_child[*history_count];
        if (child >= 0) {
            const size_t root = (size_t)history_root[*history_count];
            parent[(size_t)child] = (size_t)child;
            set_size[root] = (size_t)history_size[*history_count];
        }
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t persistent_unionfind(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + 4 * q) return -1;

    int64_t kind[MAX_Q], u[MAX_Q], v[MAX_Q];
    int64_t first_child[MAX_Q + 1], next_sibling[MAX_Q];
    int64_t answer[MAX_Q + 1] = {0};
    for (size_t node = 0; node <= q; ++node) first_child[node] = -1;
    size_t query_count = 0;
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t offset = 2 + 4 * operation;
        kind[operation] = input[offset];
        const int64_t version = input[offset + 1];
        u[operation] = input[offset + 2];
        v[operation] = input[offset + 3];
        if ((kind[operation] != 0 && kind[operation] != 1) ||
            version < -1 || version >= (int64_t)operation ||
            u[operation] < 0 || u[operation] >= n_value ||
            v[operation] < 0 || v[operation] >= n_value) return -1;
        if (version >= 0 && kind[(size_t)version] != 0) return -1;
        if (kind[operation] == 1) ++query_count;
        const size_t parent_node = (size_t)(version + 1);
        next_sibling[operation] = first_child[parent_node];
        first_child[parent_node] = (int64_t)(operation + 1);
    }

    const size_t required = 8 * query_count;
    if (output == NULL || capacity < required) return -2;
    size_t parent[MAX_N], set_size[MAX_N];
    for (size_t item = 0; item < n; ++item) {
        parent[item] = item;
        set_size[item] = 1;
    }
    int64_t history_child[MAX_Q], history_root[MAX_Q], history_size[MAX_Q];
    size_t history_count = 0;
    visit_version(0, kind, u, v, first_child, next_sibling, parent, set_size,
                  answer, history_child, history_root, history_size, &history_count);
    size_t written = 0;
    for (size_t operation = 0; operation < q; ++operation) {
        if (kind[operation] == 1) {
            store_i64_le(output, written, answer[operation + 1]);
            written += 8;
        }
    }
    return (int64_t)written;
}
