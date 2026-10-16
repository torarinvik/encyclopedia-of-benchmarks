#include <cstddef>
#include <cstdint>

constexpr int MAX_VERTICES = 128;

static void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t heavy_light_decomposition_metadata(const std::int64_t *input, std::size_t length,
                                                            std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2) return -1;
    auto nv = input[0], mv = input[1];
    if (nv < 1 || nv > MAX_VERTICES || mv != nv - 1 || length != 2 + 2 * static_cast<std::size_t>(mv)) return -1;
    int n = static_cast<int>(nv), m = static_cast<int>(mv);
    int adjacency[MAX_VERTICES * MAX_VERTICES]{};
    int degree[MAX_VERTICES]{};
    for (int edge = 0; edge < m; ++edge) {
        auto uv = input[2 + 2 * edge], vv = input[3 + 2 * edge];
        if (uv < 0 || uv >= nv || vv < 0 || vv >= nv || uv == vv) return -1;
        int u = static_cast<int>(uv), v = static_cast<int>(vv);
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
    std::size_t required = (1 + 3 * static_cast<std::size_t>(n)) * 8;
    if (output == nullptr || capacity < required) return -2;
    std::size_t cursor = 0;
    put_i64(output, cursor++ * 8, nv);
    for (int vertex = 0; vertex < n; ++vertex) {
        put_i64(output, cursor++ * 8, position[vertex]);
        put_i64(output, cursor++ * 8, head[vertex]);
        put_i64(output, cursor++ * 8, big_child[vertex]);
    }
    return static_cast<std::int64_t>(required);
}
