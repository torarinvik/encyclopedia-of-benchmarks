#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 8;
constexpr std::size_t max_input_length = 58;

bool has_cycle(std::size_t n, const std::uint8_t *graph, std::uint8_t *visited,
               std::size_t current, std::size_t position) noexcept {
    if (position == n) return graph[current * max_vertices] != 0;
    for (std::size_t next = 0; next < n; ++next) {
        if (graph[current * max_vertices + next] && !visited[next]) {
            visited[next] = 1;
            if (has_cycle(n, graph, visited, next, position + 1)) return true;
            visited[next] = 0;
        }
    }
    return false;
}
}

extern "C" std::int64_t hamiltonian_cycle_exists(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (!input || length < 2 || length > max_input_length) return -1;
    if (input[0] < 3 || input[0] > static_cast<std::int64_t>(max_vertices) || input[1] < 0) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (input[1] > static_cast<std::int64_t>(n * (n - 1) / 2)) return -1;
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * m) return -1;
    std::uint8_t graph[max_vertices * max_vertices]{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= static_cast<std::int64_t>(n) || v_value >= static_cast<std::int64_t>(n) || u_value == v_value) return -1;
        const auto u = static_cast<std::size_t>(u_value), v = static_cast<std::size_t>(v_value);
        if (graph[u * max_vertices + v]) return -1;
        graph[u * max_vertices + v] = graph[v * max_vertices + u] = 1;
    }
    std::uint8_t visited[max_vertices]{};
    visited[0] = 1;
    return has_cycle(n, graph, visited, 0, 1) ? 1 : 0;
}
