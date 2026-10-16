#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 12;

bool assign_colors(const std::int64_t *input, std::size_t count, std::size_t max_colors,
                   std::size_t vertex, std::int64_t *colors) {
    if (vertex == count) return true;
    for (std::size_t color = 0; color < max_colors; ++color) {
        bool safe = true;
        for (std::size_t neighbor = 0; neighbor < count; ++neighbor) {
            if (input[2 + vertex * count + neighbor] == 1 && colors[neighbor] == static_cast<std::int64_t>(color)) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = static_cast<std::int64_t>(color);
        if (assign_colors(input, count, max_colors, vertex + 1, colors)) return true;
        colors[vertex] = -1;
    }
    return false;
}

void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t graph_m_coloring_backtracking(const std::int64_t *input, std::size_t length,
                                                       std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2) return -1;
    const std::int64_t n_value = input[0], colors_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_vertices) ||
        colors_value < 0 || colors_value > static_cast<std::int64_t>(max_vertices)) return -1;
    const auto n = static_cast<std::size_t>(n_value), max_colors = static_cast<std::size_t>(colors_value);
    if (length != 2 + n * n) return -1;
    for (std::size_t row = 0; row < n; ++row) {
        if (input[2 + row * n + row] != 0) return -1;
        for (std::size_t column = 0; column < n; ++column) {
            const auto cell = input[2 + row * n + column];
            if ((cell != 0 && cell != 1) || cell != input[2 + column * n + row]) return -1;
        }
    }
    std::int64_t colors[max_vertices];
    for (std::size_t vertex = 0; vertex < n; ++vertex) colors[vertex] = -1;
    if (!assign_colors(input, n, max_colors, 0, colors)) return 0;
    const std::size_t required = n * 8;
    if (required == 0) return 0;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t vertex = 0; vertex < n; ++vertex) put_i64(output, vertex * 8, colors[vertex]);
    return static_cast<std::int64_t>(required);
}
