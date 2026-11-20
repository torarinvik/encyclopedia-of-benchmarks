/* Brélaz saturation-degree greedy coloring on a bounded simple graph. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 12;
constexpr std::size_t max_edges = 66;
constexpr std::size_t max_valid_length = 134;
constexpr std::size_t max_parseable_length = 135;

int bit_count(std::uint16_t value) noexcept {
    int count = 0;
    while (value != 0) {
        count += value & 1u;
        value >>= 1;
    }
    return count;
}
}

extern "C" std::int64_t dsatur_greedy_coloring(const std::int64_t* input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_length) return -1;

    const std::int64_t raw_vertices = input[0];
    const std::int64_t raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > static_cast<std::int64_t>(max_vertices) ||
        raw_edges < 0 || raw_edges > static_cast<std::int64_t>(max_edges)) return -1;

    const std::size_t vertex_count = static_cast<std::size_t>(raw_vertices);
    const std::size_t edge_count = static_cast<std::size_t>(raw_edges);
    if (length != 2 + 2 * edge_count || length > max_valid_length) return -1;

    std::uint16_t adjacency[max_vertices]{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::int64_t raw_first = input[2 + 2 * edge];
        const std::int64_t raw_second = input[3 + 2 * edge];
        if (raw_first < 0 || raw_first >= raw_second || raw_second >= raw_vertices) return -1;
        const std::size_t first = static_cast<std::size_t>(raw_first);
        const std::size_t second = static_cast<std::size_t>(raw_second);
        const std::uint16_t first_bit = static_cast<std::uint16_t>(1u << second);
        if ((adjacency[first] & first_bit) != 0) return -1;
        adjacency[first] |= first_bit;
        adjacency[second] |= static_cast<std::uint16_t>(1u << first);
    }

    int colors[max_vertices];
    std::uint16_t saturation_colors[max_vertices]{};
    int residual_degree[max_vertices]{};
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        colors[vertex] = -1;
        residual_degree[vertex] = bit_count(adjacency[vertex]);
    }

    int color_count = 0;
    for (std::size_t round = 0; round < vertex_count; ++round) {
        int selected = -1;
        for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
            if (colors[vertex] >= 0) continue;
            if (selected < 0) {
                selected = static_cast<int>(vertex);
                continue;
            }
            const int saturation = bit_count(saturation_colors[vertex]);
            const int selected_saturation = bit_count(saturation_colors[selected]);
            if (saturation > selected_saturation ||
                (saturation == selected_saturation &&
                 (residual_degree[vertex] > residual_degree[selected] ||
                  (residual_degree[vertex] == residual_degree[selected] &&
                   vertex < static_cast<std::size_t>(selected))))) {
                selected = static_cast<int>(vertex);
            }
        }

        const std::uint16_t used = saturation_colors[selected];
        int color = 0;
        while ((used & static_cast<std::uint16_t>(1u << color)) != 0) ++color;
        colors[selected] = color;
        if (color + 1 > color_count) color_count = color + 1;

        for (std::size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
            if ((adjacency[selected] & static_cast<std::uint16_t>(1u << neighbor)) == 0 ||
                colors[neighbor] >= 0) continue;
            --residual_degree[neighbor];
            saturation_colors[neighbor] |= static_cast<std::uint16_t>(1u << color);
        }
    }

    std::uint64_t packed = static_cast<std::uint64_t>(color_count) << 48;
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex)
        packed |= static_cast<std::uint64_t>(colors[vertex]) << (4 * vertex);
    return static_cast<std::int64_t>(packed);
}
