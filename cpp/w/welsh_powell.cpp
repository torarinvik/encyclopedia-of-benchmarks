#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 32;
constexpr std::size_t max_edge_pairs = 512;
constexpr std::size_t max_validation_length = 2 + 2 * max_edge_pairs + 1;
constexpr std::size_t output_bytes_per_vertex = 8;

constexpr std::uint64_t vertex_bit(std::size_t vertex) noexcept {
    return UINT64_C(1) << vertex;
}

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < output_bytes_per_vertex; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}
}

extern "C" std::int64_t welsh_powell(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_validation_length) return -1;
    const std::int64_t n64 = input[0];
    const std::int64_t edge_count64 = input[1];
    if (n64 < 0 || n64 > static_cast<std::int64_t>(max_vertices) ||
        edge_count64 < 0 || edge_count64 > static_cast<std::int64_t>(max_edge_pairs)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto edge_count = static_cast<std::size_t>(edge_count64);
    if (length != 2 + 2 * edge_count) return -1;

    std::array<std::uint64_t, max_vertices> adjacency{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::int64_t left64 = input[2 + 2 * edge];
        const std::int64_t right64 = input[3 + 2 * edge];
        if (left64 < 0 || left64 >= n64 || right64 < 0 || right64 >= n64 || left64 == right64) return -1;
        const auto left = static_cast<std::size_t>(left64);
        const auto right = static_cast<std::size_t>(right64);
        adjacency[left] |= vertex_bit(right);
        adjacency[right] |= vertex_bit(left);
    }

    const std::size_t output_bytes = n * output_bytes_per_vertex;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<std::size_t, max_vertices> degrees{};
    std::array<std::size_t, max_vertices> order{};
    std::array<std::int64_t, max_vertices> colors{};
    colors.fill(-1);
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        order[vertex] = vertex;
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if ((adjacency[vertex] & vertex_bit(neighbor)) != 0) ++degrees[vertex];
        }
    }

    // Stable descending degree order keeps equal-degree vertices by index.
    for (std::size_t index = 1; index < n; ++index) {
        const auto key = order[index];
        std::size_t position = index;
        while (position > 0 && degrees[order[position - 1]] < degrees[key]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }

    std::uint64_t colored_vertices = 0;
    for (std::size_t index = 0; index < n; ++index) {
        const auto vertex = order[index];
        if (colors[vertex] >= 0) continue;

        std::uint64_t used_colors = 0;
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if ((adjacency[vertex] & vertex_bit(neighbor)) != 0 && colors[neighbor] >= 0) {
                used_colors |= vertex_bit(static_cast<std::size_t>(colors[neighbor]));
            }
        }
        std::size_t color = 0;
        while ((used_colors & vertex_bit(color)) != 0) ++color;
        colors[vertex] = static_cast<std::int64_t>(color);
        colored_vertices |= vertex_bit(vertex);

        for (std::size_t other_index = 0; other_index < n; ++other_index) {
            const auto other = order[other_index];
            if (colors[other] < 0 && (adjacency[other] & colored_vertices) == 0) {
                colors[other] = static_cast<std::int64_t>(color);
                colored_vertices |= vertex_bit(other);
            }
        }
    }

    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        put_i64_le(output, vertex * output_bytes_per_vertex, colors[vertex]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
