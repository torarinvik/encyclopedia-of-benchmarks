#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 128

static void put_i64(uint8_t *output, size_t slot, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[slot * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

static int64_t max_i64(int64_t left, int64_t right) {
    return left > right ? left : right;
}

static int64_t range_max(const int64_t *tree, int n, int left, int right) {
    int l = left + n, r = right + n + 1;
    int64_t maximum = INT32_MIN;
    while (l < r) {
        if (l & 1) maximum = max_i64(maximum, tree[l++]);
        if (r & 1) maximum = max_i64(maximum, tree[--r]);
        l >>= 1;
        r >>= 1;
    }
    return maximum;
}

static void point_set(int64_t *tree, int n, int position, int64_t value) {
    int p = position + n;
    tree[p] = value;
    while (p > 1) {
        p >>= 1;
        tree[p] = max_i64(tree[p * 2], tree[p * 2 + 1]);
    }
}

static int64_t path_max(const int64_t *tree, int n, const int *parent,
        const int *depth, const int *head, const int *position, int a, int b) {
    int64_t result = INT32_MIN;
    while (head[a] != head[b]) {
        if (depth[head[a]] < depth[head[b]]) { int t = a; a = b; b = t; }
        result = max_i64(result, range_max(tree, n, position[head[a]], position[a]));
        a = parent[head[a]];
    }
    if (depth[a] > depth[b]) { int t = a; a = b; b = t; }
    return max_i64(result, range_max(tree, n, position[a], position[b]));
}

int64_t heavy_light_path_max(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    int n = (int)n_value, q = (int)q_value;
    if (length != (size_t)(3 * n + 3 * q)) return -1;

    int64_t values[MAX_N];
    size_t cursor = 2;
    for (int v = 0; v < n; ++v) {
        values[v] = input[cursor++];
        if (values[v] < -2147483648LL || values[v] > 2147483647LL) return -1;
    }
    int adjacency[MAX_N][MAX_N] = {{0}}, degree[MAX_N] = {0};
    for (int edge = 0; edge < n - 1; ++edge) {
        int64_t uv = input[cursor++], vv = input[cursor++];
        if (uv < 0 || uv >= n || vv < 0 || vv >= n || uv == vv) return -1;
        int u = (int)uv, v = (int)vv;
        for (int i = 0; i < degree[u]; ++i) if (adjacency[u][i] == v) return -1;
        adjacency[u][degree[u]++] = v;
        adjacency[v][degree[v]++] = u;
    }

    int parent[MAX_N], depth[MAX_N] = {0}, order[MAX_N], stack[MAX_N];
    for (int v = 0; v < n; ++v) parent[v] = -2;
    parent[0] = -1;
    int top = 0, order_count = 0;
    stack[top++] = 0;
    while (top > 0) {
        int u = stack[--top];
        order[order_count++] = u;
        for (int i = 0; i < degree[u]; ++i) {
            int v = adjacency[u][i];
            if (v == parent[u]) continue;
            if (parent[v] != -2) return -1;
            parent[v] = u;
            depth[v] = depth[u] + 1;
            stack[top++] = v;
        }
    }
    if (order_count != n) return -1;

    int subtree[MAX_N], heavy[MAX_N];
    for (int v = 0; v < n; ++v) { subtree[v] = 1; heavy[v] = -1; }
    for (int i = n - 1; i > 0; --i) {
        int v = order[i], p = parent[v];
        subtree[p] += subtree[v];
        if (heavy[p] < 0 || subtree[v] > subtree[heavy[p]]) heavy[p] = v;
    }

    int head[MAX_N], position[MAX_N], todo_vertex[MAX_N], todo_head[MAX_N];
    int todo = 0, timer = 0;
    todo_vertex[todo] = 0; todo_head[todo++] = 0;
    int64_t base[MAX_N];
    while (todo > 0) {
        --todo;
        int u = todo_vertex[todo], chain = todo_head[todo];
        while (u >= 0) {
            head[u] = chain;
            position[u] = timer;
            base[timer++] = values[u];
            for (int i = 0; i < degree[u]; ++i) {
                int v = adjacency[u][i];
                if (parent[v] == u && v != heavy[u]) {
                    todo_vertex[todo] = v; todo_head[todo++] = v;
                }
            }
            u = heavy[u];
        }
    }

    int64_t segment[2 * MAX_N] = {0};
    for (int i = 0; i < n; ++i) segment[n + i] = base[i];
    for (int i = n - 1; i > 0; --i) segment[i] = max_i64(segment[2 * i], segment[2 * i + 1]);

    int64_t results[MAX_Q];
    int result_count = 0;
    size_t operations = cursor;
    for (int i = 0; i < q; ++i) {
        int64_t op = input[operations + 3 * (size_t)i];
        int64_t av = input[operations + 3 * (size_t)i + 1];
        int64_t bv = input[operations + 3 * (size_t)i + 2];
        if (op == 0) {
            if (av < 0 || av >= n || bv < -2147483648LL || bv > 2147483647LL) return -1;
            values[av] = bv;
            point_set(segment, n, position[av], bv);
        } else if (op == 1) {
            if (av < 0 || av >= n || bv < 0 || bv >= n) return -1;
            results[result_count++] = path_max(segment, n, parent, depth, head, position, (int)av, (int)bv);
        } else return -1;
    }

    size_t output_bytes = (size_t)result_count * 8;
    if (output_bytes > 0 && (output == NULL || capacity < output_bytes)) return -2;
    for (int i = 0; i < result_count; ++i) put_i64(output, (size_t)i, results[i]);
    return (int64_t)output_bytes;
}
