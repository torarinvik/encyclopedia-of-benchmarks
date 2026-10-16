/* Detect cycles in a bounded simple undirected graph with iterative DFS. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t undirected_cycle_check(const std::int64_t *input,
                                                 std::size_t length) noexcept
{
    constexpr std::size_t max_vertices = 32;
    constexpr std::size_t max_edges = 256;
    if (input == nullptr || length < 2 || input[0] < 0 || input[0] > 32 ||
        input[1] < 0 || input[1] > 256) return -1;
    const auto vertices = static_cast<std::size_t>(input[0]);
    const auto edges = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edges) return -1;

    std::array<bool, max_vertices * max_vertices> adjacency{};
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto left = input[2 + 2 * edge];
        const auto right = input[3 + 2 * edge];
        if (left < 0 || left >= static_cast<std::int64_t>(vertices) || right < 0 ||
            right >= static_cast<std::int64_t>(vertices)) return -1;
        const auto forward = static_cast<std::size_t>(left) * max_vertices + static_cast<std::size_t>(right);
        const auto reverse = static_cast<std::size_t>(right) * max_vertices + static_cast<std::size_t>(left);
        if (adjacency[forward]) return -1;
        adjacency[forward] = true;
        adjacency[reverse] = true;
    }

    std::array<bool, max_vertices> visited{};
    std::array<std::size_t, max_vertices> stack_vertex{};
    std::array<std::size_t, max_vertices> stack_parent{};
    for (std::size_t start = 0; start < vertices; ++start) {
        if (visited[start]) continue;
        std::size_t top = 1;
        stack_vertex[0] = start;
        stack_parent[0] = max_vertices;
        visited[start] = true;
        while (top != 0) {
            --top;
            const auto current = stack_vertex[top];
            const auto parent = stack_parent[top];
            for (std::size_t neighbor = 0; neighbor < vertices; ++neighbor) {
                if (!adjacency[current * max_vertices + neighbor] || neighbor == parent) continue;
                if (visited[neighbor]) return 1;
                visited[neighbor] = true;
                stack_vertex[top] = neighbor;
                stack_parent[top] = current;
                ++top;
            }
        }
    }
    return 0;
}
