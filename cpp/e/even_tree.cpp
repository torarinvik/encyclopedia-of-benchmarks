#include <cstddef>
#include <cstdint>

extern "C" std::int64_t even_tree(const std::int64_t *values, std::size_t length) noexcept
{
    constexpr std::int64_t invalid = INT64_MIN;
    if (values == nullptr || length < 2) return invalid;
    const auto n_value = values[0], edge_value = values[1];
    if (n_value < 2 || n_value > 100 || n_value % 2 != 0 || edge_value != n_value - 1) return invalid;
    const auto n = static_cast<std::size_t>(n_value), edge_count = static_cast<std::size_t>(edge_value);
    if (length != 2 + 2 * edge_count) return invalid;
    bool adjacency[100][100]{};
    for (std::size_t i = 0; i < edge_count; ++i) {
        const auto u_value = values[2 + 2 * i], v_value = values[3 + 2 * i];
        if (u_value < 1 || u_value > n_value || v_value < 1 || v_value > n_value || u_value == v_value) return invalid;
        const auto u = static_cast<std::size_t>(u_value - 1), v = static_cast<std::size_t>(v_value - 1);
        if (adjacency[u][v]) return invalid;
        adjacency[u][v] = adjacency[v][u] = true;
    }
    int parent[100], stack[100], order[100];
    std::int64_t subtree[100];
    for (std::size_t i = 0; i < n; ++i) { parent[i] = -2; subtree[i] = 1; }
    parent[0] = -1;
    std::size_t top = 0, order_count = 0;
    stack[top++] = 0;
    while (top > 0) {
        const int u = stack[--top];
        order[order_count++] = u;
        for (std::size_t v = 0; v < n; ++v) if (adjacency[u][v] && parent[v] == -2) {
            parent[v] = u;
            stack[top++] = static_cast<int>(v);
        }
    }
    if (order_count != n) return invalid;
    std::int64_t cuts = 0;
    for (std::size_t i = order_count; i-- > 0;) {
        const int u = order[i];
        if (parent[u] >= 0) subtree[parent[u]] += subtree[u];
        if (subtree[u] % 2 == 0) ++cuts;
    }
    return cuts - 1;
}
