#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 256
#define MAX_INPUT_VALUES (2 + 4 * MAX_Q)
#define MODULUS INT64_C(998244353)

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static size_t find_root(size_t *parent, int64_t *difference, size_t item) {
    if (parent[item] != item) {
        const size_t old_parent = parent[item];
        const size_t root = find_root(parent, difference, old_parent);
        difference[item] = normalize(difference[item] + difference[old_parent]);
        parent[item] = root;
    }
    return parent[item];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t unionfind_with_potential(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + 4 * q) return -1;

    for (size_t operation = 0; operation < q; ++operation) {
        const size_t position = 2 + 4 * operation;
        const int64_t kind = input[position], u = input[position + 1];
        const int64_t v = input[position + 2], x = input[position + 3];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
        if (kind == 0) {
            if (x < 0 || x >= MODULUS) return -1;
        } else if (kind == 1) {
            if (x != 0) return -1;
        } else {
            return -1;
        }
    }
    const size_t required = 8 * q;
    if (output == NULL || capacity < required) return -2;

    size_t parent[MAX_N], set_size[MAX_N];
    int64_t difference[MAX_N];
    for (size_t item = 0; item < n; ++item) {
        parent[item] = item;
        set_size[item] = 1;
        difference[item] = 0;
    }
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t position = 2 + 4 * operation;
        const int64_t kind = input[position];
        const size_t u = (size_t)input[position + 1];
        const size_t v = (size_t)input[position + 2];
        const int64_t x = input[position + 3];
        const size_t root_u = find_root(parent, difference, u);
        const size_t root_v = find_root(parent, difference, v);
        int64_t answer;
        if (kind == 1) {
            answer = root_u == root_v ? normalize(difference[u] - difference[v]) : -1;
        } else if (root_u == root_v) {
            answer = normalize(difference[u] - difference[v]) == x;
        } else if (set_size[root_u] < set_size[root_v]) {
            parent[root_u] = root_v;
            difference[root_u] = normalize(x - difference[u] + difference[v]);
            set_size[root_v] += set_size[root_u];
            answer = 1;
        } else {
            parent[root_v] = root_u;
            difference[root_v] = normalize(difference[u] - difference[v] - x);
            set_size[root_u] += set_size[root_v];
            answer = 1;
        }
        store_i64_le(output, 8 * operation, answer);
    }
    return (int64_t)required;
}
