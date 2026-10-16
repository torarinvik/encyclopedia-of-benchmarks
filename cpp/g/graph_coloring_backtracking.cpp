#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = 2016;

bool color_vertex(std::size_t vertex, std::size_t count, const bool *adjacency, std::int64_t *colors) {
    if (vertex == count) return true;
    for (std::int64_t color = 1; color <= static_cast<std::int64_t>(count); ++color) {
        bool safe = true;
        for (std::size_t neighbor = 0; neighbor < count; ++neighbor) {
            if (adjacency[vertex * max_vertices + neighbor] && colors[neighbor] == color) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = color;
        if (color_vertex(vertex + 1, count, adjacency, colors)) return true;
        colors[vertex] = 0;
    }
    return false;
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t graph_coloring_backtracking(const std::int64_t *input, std::size_t length,
                                                     std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2) return -1;
    const std::int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_vertices) ||
        m_value < 0 || m_value > static_cast<std::int64_t>(max_edges) ||
        length != 2 + 2 * static_cast<std::size_t>(m_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value), m = static_cast<std::size_t>(m_value);
    bool adjacency[max_vertices * max_vertices] = {};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value)
            return -1;
        const auto u = static_cast<std::size_t>(u_value), v = static_cast<std::size_t>(v_value);
        adjacency[u * max_vertices + v] = adjacency[v * max_vertices + u] = true;
    }
    std::int64_t colors[max_vertices] = {};
    if (!color_vertex(0, n, adjacency, colors)) return -1;
    std::int64_t colors_used = 0;
    for (std::size_t vertex = 0; vertex < n; ++vertex)
        if (colors[vertex] > colors_used) colors_used = colors[vertex];
    std::int64_t packed[max_vertices + 2] = {};
    packed[0] = n_value;
    for (std::size_t vertex = 0; vertex < n; ++vertex) packed[vertex + 1] = colors[vertex];
    packed[n + 1] = colors_used;
    const std::size_t used = n + 2, required = used * 8;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < used; ++index) put_i64(output, index * 8, packed[index]);
    return static_cast<std::int64_t>(required);
}
