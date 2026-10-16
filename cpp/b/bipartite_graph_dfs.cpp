#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = 256;
constexpr std::size_t max_input_length = 2 + 2 * max_edges;
constexpr std::size_t max_cells = max_vertices * max_vertices;
}

extern "C" std::int64_t bipartite_graph_dfs(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_vertices) || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_edges)) return -1;
    const auto n = static_cast<std::size_t>(input[0]), m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;

    std::uint8_t adjacency[max_cells] = {};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || from_value >= static_cast<std::int64_t>(n) || to_value < 0 || to_value >= static_cast<std::int64_t>(n)) return -1;
        const auto from = static_cast<std::size_t>(from_value), to = static_cast<std::size_t>(to_value);
        adjacency[from * n + to] = 1;
        adjacency[to * n + from] = 1;
    }

    std::int8_t color[max_vertices];
    std::size_t stack[max_vertices];
    for (std::size_t i = 0; i < n; ++i) color[i] = -1;
    for (std::size_t start = 0; start < n; ++start) {
        if (color[start] != -1) continue;
        std::size_t top = 0;
        stack[top++] = start;
        color[start] = 0;
        while (top > 0) {
            const auto node = stack[--top];
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacency[node * n + neighbor] == 0) continue;
                if (color[neighbor] == -1) {
                    color[neighbor] = static_cast<std::int8_t>(1 - color[node]);
                    stack[top++] = neighbor;
                } else if (color[neighbor] == color[node]) return 0;
            }
        }
    }
    return 1;
}
