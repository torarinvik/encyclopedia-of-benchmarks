#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 64

static size_t find_parity(int64_t *parent, int64_t *parity, size_t node, int64_t *xor_to_root) {
    size_t root = node;
    int64_t total = 0;
    while ((size_t)parent[root] != root) { total ^= parity[root]; root = (size_t)parent[root]; }
    size_t current = node;
    int64_t accumulated = 0;
    while ((size_t)parent[current] != current) {
        const size_t next = (size_t)parent[current];
        const int64_t edge = parity[current];
        parent[current] = (int64_t)root;
        parity[current] = total ^ accumulated;
        accumulated ^= edge;
        current = next;
    }
    *xor_to_root = total;
    return root;
}

int64_t online_bipartiteness_dsu(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 195) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + 3 * q) return -1;
    for (size_t j = 0; j < q; ++j) {
        const int64_t opcode = input[2 + 3 * j], a = input[3 + 3 * j], b = input[4 + 3 * j];
        if (opcode == 0) { if (a < 0 || a >= n_value || b < 0 || b >= n_value) return -1; }
        else if (opcode == 1) { if (a < 0 || a >= n_value || b != 0) return -1; }
        else return -1;
    }
    int64_t parent[MAX_N], size[MAX_N], parity[MAX_N], bad[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) { parent[i] = (int64_t)i; size[i] = 1; parity[i] = 0; }
    int64_t checksum = 0, query_ordinal = 0;
    for (size_t j = 0; j < q; ++j) {
        const int64_t opcode = input[2 + 3 * j];
        const size_t a = (size_t)input[3 + 3 * j];
        if (opcode == 1) {
            int64_t ignored = 0;
            const size_t root = find_parity(parent, parity, a, &ignored);
            const int64_t answer = bad[root] ? 0 : 1;
            checksum += (query_ordinal + 1) * (answer + 1);
            ++query_ordinal;
            continue;
        }
        const size_t b = (size_t)input[4 + 3 * j];
        int64_t parity_a = 0, parity_b = 0;
        size_t root_a = find_parity(parent, parity, a, &parity_a);
        size_t root_b = find_parity(parent, parity, b, &parity_b);
        if (root_a == root_b) {
            if (parity_a == parity_b) bad[root_a] = 1;
            continue;
        }
        if (size[root_a] < size[root_b]) {
            const size_t old_root = root_a; root_a = root_b; root_b = old_root;
            const int64_t old_parity = parity_a; parity_a = parity_b; parity_b = old_parity;
        }
        parent[root_b] = (int64_t)root_a;
        parity[root_b] = parity_a ^ parity_b ^ 1;
        size[root_a] += size[root_b];
        bad[root_a] = bad[root_a] || bad[root_b];
    }
    return checksum;
}
