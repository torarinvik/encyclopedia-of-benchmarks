#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 128

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t heavy_light_decomposition_metadata(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > MAX_VERTICES || m_value != n_value - 1
            || length != 2 + 2 * (size_t)m_value) return -1;
    int n = (int)n_value, m = (int)m_value;
    int adjacency[MAX_VERTICES * MAX_VERTICES] = {0};
    int degree[MAX_VERTICES] = {0};
    for (int edge = 0; edge < m; ++edge) {
        int64_t u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value) return -1;
        int u = (int)u_value, v = (int)v_value;
        for (int i = 0; i < degree[u]; ++i) if (adjacency[u * MAX_VERTICES + i] == v) return -1;
        adjacency[u * MAX_VERTICES + degree[u]++] = v;
        adjacency[v * MAX_VERTICES + degree[v]++] = u;
    }

    int parent[MAX_VERTICES], order[MAX_VERTICES], stack[MAX_VERTICES];
    for (int v = 0; v < n; ++v) parent[v] = -2;
    parent[0] = -1;
    int top = 0, order_count = 0;
    stack[top++] = 0;
    while (top > 0) {
        int vertex = stack[--top];
        order[order_count++] = vertex;
        for (int i = degree[vertex] - 1; i >= 0; --i) {
            int child = adjacency[vertex * MAX_VERTICES + i];
            if (parent[child] == -2) {
                parent[child] = vertex;
                stack[top++] = child;
            }
        }
    }
    if (order_count != n) return -1;

    int subtree_size[MAX_VERTICES], big_child[MAX_VERTICES];
    for (int index = n - 1; index >= 0; --index) {
        int vertex = order[index], best_size = 0;
        subtree_size[vertex] = 1;
        big_child[vertex] = -1;
        for (int i = 0; i < degree[vertex]; ++i) {
            int child = adjacency[vertex * MAX_VERTICES + i];
            if (parent[child] != vertex) continue;
            subtree_size[vertex] += subtree_size[child];
            if (subtree_size[child] > best_size) {
                best_size = subtree_size[child];
                big_child[vertex] = child;
            }
        }
    }

    int position[MAX_VERTICES], head[MAX_VERTICES], stack_head[MAX_VERTICES];
    top = 0;
    int next_position = 0;
    stack[top] = 0;
    stack_head[top++] = 0;
    while (top > 0) {
        --top;
        int vertex = stack[top], chain_head = stack_head[top];
        position[vertex] = next_position++;
        head[vertex] = chain_head;
        for (int i = degree[vertex] - 1; i >= 0; --i) {
            int child = adjacency[vertex * MAX_VERTICES + i];
            if (parent[child] == vertex && child != big_child[vertex]) {
                stack[top] = child;
                stack_head[top++] = child;
            }
        }
        if (big_child[vertex] >= 0) {
            stack[top] = big_child[vertex];
            stack_head[top++] = chain_head;
        }
    }

    size_t value_count = 1 + 3 * (size_t)n;
    size_t required = value_count * 8;
    if (output == NULL || capacity < required) return -2;
    put_i64(output, 0, n);
    size_t cursor = 1;
    for (int vertex = 0; vertex < n; ++vertex) {
        put_i64(output, cursor++ * 8, position[vertex]);
        put_i64(output, cursor++ * 8, head[vertex]);
        put_i64(output, cursor++ * 8, big_child[vertex]);
    }
    return (int64_t)required;
}
