/* Dynamic tree MWIS with HLD and max-plus chain products. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define DMW_MAX_N 64
#define DMW_MAX_Q 64
#define DMW_MAX_INPUT 320
#define DMW_NEG (-(INT64_C(1) << 60))

typedef struct { int64_t a[2][2]; } Dmw_Matrix;

static int64_t dmw_max64(int64_t a, int64_t b) { return a > b ? a : b; }

static Dmw_Matrix dmw_identity(void) {
    Dmw_Matrix m = {{{0, DMW_NEG}, {DMW_NEG, 0}}};
    return m;
}

static Dmw_Matrix dmw_multiply(Dmw_Matrix left, Dmw_Matrix right) {
    Dmw_Matrix result;
    for (int i = 0; i < 2; ++i) {
        for (int j = 0; j < 2; ++j) {
            int64_t a = left.a[i][0] + right.a[0][j];
            int64_t b = left.a[i][1] + right.a[1][j];
            result.a[i][j] = dmw_max64(a, b);
        }
    }
    return result;
}

static int dmw_find(int parent[DMW_MAX_N], int v) {
    while (parent[v] != v) {
        parent[v] = parent[parent[v]];
        v = parent[v];
    }
    return v;
}

static void dmw_set(Dmw_Matrix tree[2 * DMW_MAX_N], int position, Dmw_Matrix value) {
    int node = DMW_MAX_N + position;
    tree[node] = value;
    for (node /= 2; node > 0; node /= 2)
        tree[node] = dmw_multiply(tree[2 * node], tree[2 * node + 1]);
}

static Dmw_Matrix dmw_query(const Dmw_Matrix tree[2 * DMW_MAX_N], int left, int right) {
    Dmw_Matrix before = dmw_identity(), after = dmw_identity();
    left += DMW_MAX_N;
    right += DMW_MAX_N;
    while (left < right) {
        if (left & 1) before = dmw_multiply(before, tree[left++]);
        if (right & 1) after = dmw_multiply(tree[--right], after);
        left /= 2;
        right /= 2;
    }
    return dmw_multiply(before, after);
}

static void dmw_summary(const Dmw_Matrix tree[2 * DMW_MAX_N], int head[DMW_MAX_N],
                        int position[DMW_MAX_N], int tail[DMW_MAX_N], int h,
                        int64_t result[2]) {
    Dmw_Matrix product = dmw_query(tree, position[h], position[tail[h]] + 1);
    result[0] = dmw_max64(product.a[0][0], product.a[0][1]);
    result[1] = dmw_max64(product.a[1][0], product.a[1][1]);
}

static void dmw_store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte) output[offset + (size_t)byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t dynamic_tree_maximum_weight_independent_set(const int64_t *input, size_t length,
                                                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > DMW_MAX_INPUT) return -1;
    int64_t nn = input[0], qq = input[1];
    if (nn < 1 || nn > DMW_MAX_N || qq < 0 || qq > DMW_MAX_Q) return -1;
    int n = (int)nn, q = (int)qq;
    int edge_end = 2 + n + 2 * (n - 1);
    if (length != (size_t)(edge_end + 2 * q)) return -1;

    int dsu[DMW_MAX_N];
    int64_t weights[DMW_MAX_N];
    bool adjacency[DMW_MAX_N][DMW_MAX_N] = {{false}};
    for (int u = 0; u < n; ++u) dsu[u] = u;
    for (int u = 0; u < n; ++u) {
        int64_t weight = input[2 + u];
        if (weight < 0 || weight > INT64_C(1000000)) return -1;
        weights[u] = weight;
    }
    for (int e = 0; e < n - 1; ++e) {
        int offset = 2 + n + 2 * e;
        int64_t uu = input[offset], vv = input[offset + 1];
        if (uu < 0 || uu >= n || vv < 0 || vv >= n || uu == vv) return -1;
        int u = (int)uu, v = (int)vv;
        int ru = dmw_find(dsu, u), rv = dmw_find(dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv;
        adjacency[u][v] = adjacency[v][u] = true;
    }
    int root_set = dmw_find(dsu, 0);
    for (int u = 1; u < n; ++u) if (dmw_find(dsu, u) != root_set) return -1;

    int update_vertex[DMW_MAX_Q];
    int64_t update_weight[DMW_MAX_Q];
    for (int i = 0; i < q; ++i) {
        int offset = edge_end + 2 * i;
        int64_t vertex = input[offset], weight = input[offset + 1];
        if (vertex < 0 || vertex >= n || weight < 0 || weight > INT64_C(1000000)) return -1;
        update_vertex[i] = (int)vertex;
        update_weight[i] = weight;
    }
    size_t output_bytes = (size_t)q * 8;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;

    int parent[DMW_MAX_N], order[DMW_MAX_N], order_count = 1;
    for (int v = 1; v < n; ++v) parent[v] = -2;
    parent[0] = -1; order[0] = 0; order_count = 1;
    for (int i = 0; i < order_count; ++i) {
        int u = order[i];
        for (int v = 0; v < n; ++v) if (adjacency[u][v] && parent[v] == -2) {
            parent[v] = u;
            order[order_count++] = v;
        }
    }

    int subtree[DMW_MAX_N], heavy[DMW_MAX_N];
    int64_t skip[DMW_MAX_N], take[DMW_MAX_N];
    for (int u = 0; u < n; ++u) { subtree[u] = 1; heavy[u] = -1; skip[u] = 0; take[u] = weights[u]; }
    for (int i = n - 1; i > 0; --i) {
        int u = order[i], p = parent[u];
        subtree[p] += subtree[u];
        if (heavy[p] < 0 || subtree[u] > subtree[heavy[p]]) heavy[p] = u;
        skip[p] += dmw_max64(skip[u], take[u]);
        take[p] += skip[u];
    }

    int head[DMW_MAX_N], position[DMW_MAX_N], tail[DMW_MAX_N];
    int chain_stack[DMW_MAX_N], chain_count = 1, clock = 0;
    chain_stack[0] = 0;
    for (int u = 0; u < n; ++u) tail[u] = -1;
    while (chain_count > 0) {
        int h = chain_stack[--chain_count];
        for (int u = h; u != -1; u = heavy[u]) {
            head[u] = h; position[u] = clock++; tail[h] = u;
            for (int v = 1; v < n; ++v)
                if (parent[v] == u && v != heavy[u]) chain_stack[chain_count++] = v;
        }
    }

    int64_t light0[DMW_MAX_N], light1[DMW_MAX_N];
    Dmw_Matrix matrices[DMW_MAX_N], segment[2 * DMW_MAX_N];
    Dmw_Matrix identity = dmw_identity();
    for (int u = 0; u < n; ++u) {
        light0[u] = 0; light1[u] = weights[u];
        for (int v = 1; v < n; ++v) if (parent[v] == u && v != heavy[u]) {
            light0[u] += dmw_max64(skip[v], take[v]);
            light1[u] += skip[v];
        }
        matrices[u].a[0][0] = light0[u]; matrices[u].a[0][1] = light0[u];
        matrices[u].a[1][0] = light1[u]; matrices[u].a[1][1] = DMW_NEG;
    }
    for (int i = 0; i < 2 * DMW_MAX_N; ++i) segment[i] = identity;
    for (int u = 0; u < n; ++u) segment[DMW_MAX_N + position[u]] = matrices[u];
    for (int i = DMW_MAX_N - 1; i > 0; --i) segment[i] = dmw_multiply(segment[2 * i], segment[2 * i + 1]);

    int64_t staged[DMW_MAX_Q];
    for (int i = 0; i < q; ++i) {
        int vertex = update_vertex[i], h = head[vertex];
        int64_t old_state[2], new_state[2];
        dmw_summary(segment, head, position, tail, h, old_state);
        int64_t delta = update_weight[i] - weights[vertex];
        weights[vertex] = update_weight[i];
        matrices[vertex].a[1][0] += delta;
        dmw_set(segment, position[vertex], matrices[vertex]);
        dmw_summary(segment, head, position, tail, h, new_state);
        while (parent[h] != -1) {
            int p = parent[h], ph = head[p];
            int64_t before[2];
            dmw_summary(segment, head, position, tail, ph, before);
            int64_t delta0 = dmw_max64(new_state[0], new_state[1]) - dmw_max64(old_state[0], old_state[1]);
            int64_t delta1 = new_state[0] - old_state[0];
            matrices[p].a[0][0] += delta0; matrices[p].a[0][1] += delta0;
            matrices[p].a[1][0] += delta1;
            dmw_set(segment, position[p], matrices[p]);
            old_state[0] = before[0]; old_state[1] = before[1];
            dmw_summary(segment, head, position, tail, ph, new_state);
            h = ph;
        }
        int64_t answer[2];
        dmw_summary(segment, head, position, tail, 0, answer);
        staged[i] = dmw_max64(answer[0], answer[1]);
    }
    for (int i = 0; i < q; ++i) dmw_store_le(output, (size_t)i * 8, staged[i]);
    return (int64_t)output_bytes;
}
