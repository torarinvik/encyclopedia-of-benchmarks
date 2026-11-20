#include <stddef.h>
#include <stdint.h>

#define WUST_MAX_N 8
#define WUST_MAX_EDGES 28
#define WUST_WALK_LIMIT 64
#define WUST_MAX_DRAWS (WUST_WALK_LIMIT * (WUST_MAX_N - 1))
#define WUST_MAX_INPUT (4 + 2 * WUST_MAX_EDGES + WUST_MAX_DRAWS)

static void wust_write_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t wilson_uniform_spanning_tree(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > WUST_MAX_INPUT + 1) return -1;
    int64_t n0 = input[0], m0 = input[1], root0 = input[2];
    if (n0 < 1 || n0 > WUST_MAX_N || m0 < 0 || m0 > WUST_MAX_EDGES) return -1;
    size_t n = (size_t)n0, m = (size_t)m0;
    if (root0 < 0 || root0 >= n0) return -1;
    size_t root = (size_t)root0, q_at = 3 + 2 * m;
    if (length <= q_at) return -1;
    int64_t q0 = input[q_at];
    if (q0 < 0 || q0 > WUST_WALK_LIMIT * (int64_t)(n - 1)) return -1;
    size_t q = (size_t)q0;
    if (length != q_at + 1 + q) return -1;

    size_t neighbors[WUST_MAX_N][WUST_MAX_N - 1] = {{0}};
    size_t degree[WUST_MAX_N] = {0};
    int64_t prev_u = -1, prev_v = -1;
    for (size_t e = 0; e < m; ++e) {
        int64_t u0 = input[3 + 2 * e], v0 = input[4 + 2 * e];
        if (u0 < 0 || u0 >= v0 || v0 >= n0) return -1;
        if (e != 0 && (u0 < prev_u || (u0 == prev_u && v0 <= prev_v))) return -1;
        prev_u = u0; prev_v = v0;
        size_t u = (size_t)u0, v = (size_t)v0;
        neighbors[u][degree[u]++] = v;
        neighbors[v][degree[v]++] = u;
    }
    for (size_t i = 0; i < q; ++i)
        if (input[q_at + 1 + i] < 0 || input[q_at + 1 + i] > WUST_MAX_N - 2) return -1;

    uint8_t reached[WUST_MAX_N] = {0};
    size_t queue[WUST_MAX_N], head = 0, tail = 0;
    reached[root] = 1; queue[tail++] = root;
    while (head < tail) {
        size_t at = queue[head++];
        for (size_t k = 0; k < degree[at]; ++k) {
            size_t to = neighbors[at][k];
            if (!reached[to]) { reached[to] = 1; queue[tail++] = to; }
        }
    }
    for (size_t i = 0; i < n; ++i) if (!reached[i]) return -1;

    uint8_t in_tree[WUST_MAX_N] = {0};
    int64_t successor[WUST_MAX_N];
    for (size_t i = 0; i < WUST_MAX_N; ++i) successor[i] = -1;
    in_tree[root] = 1;
    size_t cursor = 0;
    for (size_t start = 0; start < n; ++start) {
        if (in_tree[start]) continue;
        size_t current = start, steps = 0;
        while (!in_tree[current]) {
            if (steps >= WUST_WALK_LIMIT || cursor >= q) return -1;
            size_t choice = (size_t)input[q_at + 1 + cursor];
            if (choice >= degree[current]) return -1;
            successor[current] = (int64_t)neighbors[current][choice];
            current = (size_t)successor[current];
            ++cursor; ++steps;
        }
        current = start;
        while (!in_tree[current]) {
            in_tree[current] = 1;
            current = (size_t)successor[current];
        }
    }
    if (cursor != q) return -1;

    size_t required = 16 * (n - 1);
    if ((required != 0 && output == NULL) || capacity < required) return -2;
    size_t offset = 0;
    for (size_t child = 0; child < n; ++child) {
        if (child == root) continue;
        wust_write_i64(output, offset, (int64_t)child); offset += 8;
        wust_write_i64(output, offset, successor[child]); offset += 8;
    }
    return (int64_t)required;
}
