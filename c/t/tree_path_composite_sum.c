#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_INPUT_VALUES (5 * MAX_N - 3)
#define MAX_OUTPUT_BYTES (8 * MAX_N)
#define MOD INT64_C(998244353)

static size_t find_root(size_t parent[MAX_N], size_t item) {
    while (parent[item] != item) {
        parent[item] = parent[parent[item]];
        item = parent[item];
    }
    return item;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t tree_path_composite_sum(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != 1 + n + 4 * (n - 1)) return -1;

    int64_t vertex_value[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        vertex_value[vertex] = input[1 + vertex];
        if (vertex_value[vertex] < 0 || vertex_value[vertex] >= MOD) return -1;
    }
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    int64_t multiplier[MAX_N][MAX_N] = {{0}};
    int64_t addend[MAX_N][MAX_N] = {{0}};
    size_t dsu_parent[MAX_N], dsu_size[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) {
        dsu_parent[vertex] = vertex;
        dsu_size[vertex] = 1;
    }
    size_t offset = 1 + n;
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const int64_t u_value = input[offset++];
        const int64_t v_value = input[offset++];
        const int64_t b = input[offset++];
        const int64_t c = input[offset++];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            u_value == v_value || b < 1 || b >= MOD || c < 0 || c >= MOD) return -1;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        size_t root_u = find_root(dsu_parent, u), root_v = find_root(dsu_parent, v);
        if (root_u == root_v) return -1;
        if (dsu_size[root_u] < dsu_size[root_v]) {
            const size_t temporary = root_u;
            root_u = root_v;
            root_v = temporary;
        }
        dsu_parent[root_v] = root_u;
        dsu_size[root_u] += dsu_size[root_v];
        adjacent[u][v] = adjacent[v][u] = 1;
        multiplier[u][v] = multiplier[v][u] = b;
        addend[u][v] = addend[v][u] = c;
    }

    size_t order[MAX_N], stack[MAX_N], order_count = 0, top = 0;
    int64_t parent[MAX_N];
    for (size_t vertex = 0; vertex < n; ++vertex) parent[vertex] = -2;
    parent[0] = -1;
    stack[top++] = 0;
    while (top > 0) {
        const size_t u = stack[--top];
        order[order_count++] = u;
        for (size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && (int64_t)v != parent[u]) {
                parent[v] = (int64_t)u;
                stack[top++] = v;
            }
        }
    }

    int64_t down_sum[MAX_N] = {0}, up_sum[MAX_N] = {0};
    size_t down_count[MAX_N] = {0}, up_count[MAX_N] = {0};
    int64_t answer[MAX_N] = {0};
    for (size_t position = order_count; position > 0; --position) {
        const size_t u = order[position - 1];
        down_sum[u] = vertex_value[u];
        down_count[u] = 1;
        for (size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && parent[v] == (int64_t)u) {
                const int64_t contribution =
                    (multiplier[u][v] * down_sum[v] + addend[u][v] * (int64_t)down_count[v]) % MOD;
                down_sum[u] = (down_sum[u] + contribution) % MOD;
                down_count[u] += down_count[v];
            }
        }
    }
    for (size_t position = 0; position < order_count; ++position) {
        const size_t u = order[position];
        int64_t total_sum = vertex_value[u];
        size_t total_count = 1;
        if (parent[u] >= 0) {
            total_sum = (total_sum + up_sum[u]) % MOD;
            total_count += up_count[u];
        }
        for (size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && parent[v] == (int64_t)u) {
                total_sum = (total_sum + multiplier[u][v] * down_sum[v]
                             + addend[u][v] * (int64_t)down_count[v]) % MOD;
                total_count += down_count[v];
            }
        }
        answer[u] = total_sum;
        for (size_t v = 0; v < n; ++v) {
            if (adjacent[u][v] && parent[v] == (int64_t)u) {
                const int64_t child_contribution =
                    (multiplier[u][v] * down_sum[v]
                     + addend[u][v] * (int64_t)down_count[v]) % MOD;
                const int64_t outside_sum = (total_sum - child_contribution + MOD) % MOD;
                const size_t outside_count = total_count - down_count[v];
                up_sum[v] = (multiplier[u][v] * outside_sum
                             + addend[u][v] * (int64_t)outside_count) % MOD;
                up_count[v] = outside_count;
            }
        }
    }

    const size_t required = 8 * n;
    if (output == NULL || capacity < required) return -2;
    for (size_t vertex = 0; vertex < n; ++vertex)
        store_i64_le(output, 8 * vertex, answer[vertex]);
    return (int64_t)required;
}
