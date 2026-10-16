#include <cstddef>
#include <cstdint>

namespace { constexpr int max_vertices = 14; }

extern "C" std::int64_t greedy_graph_coloring(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > max_vertices + 1) return -1;
    const auto count_value = values[0];
    if (count_value < 0 || count_value > max_vertices || length != static_cast<std::size_t>(count_value + 1)) return -1;
    const int count = static_cast<int>(count_value);
    const std::int64_t limit = (std::int64_t{1} << count) - 1;
    std::int64_t adjacency[max_vertices]{};
    int degree[max_vertices]{};
    int order[max_vertices]{};
    int colors[max_vertices]{};
    for (int vertex = 0; vertex < count; ++vertex) {
        const auto mask = values[1 + static_cast<std::size_t>(vertex)];
        if (mask < 0 || mask > limit || (mask & (std::int64_t{1} << vertex)) != 0) return -1;
        adjacency[vertex] = mask;
        auto remaining = mask;
        while (remaining != 0) { remaining &= remaining - 1; ++degree[vertex]; }
        order[vertex] = vertex;
    }
    for (int vertex = 0; vertex < count; ++vertex)
        for (int other = 0; other < count; ++other)
            if (((adjacency[vertex] >> other) & 1) != ((adjacency[other] >> vertex) & 1)) return -1;
    for (int index = 1; index < count; ++index) {
        const int current = order[index];
        int position = index;
        while (position > 0 && degree[order[position - 1]] < degree[current]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }
    int color_count = 0;
    for (int position = 0; position < count; ++position) {
        const int vertex = order[position];
        bool used[max_vertices + 1]{};
        for (int other = 0; other < count; ++other)
            if ((adjacency[vertex] & (std::int64_t{1} << other)) != 0 && colors[other] != 0) used[colors[other]] = true;
        int color = 1;
        while (used[color]) ++color;
        colors[vertex] = color;
        if (color > color_count) color_count = color;
    }
    std::int64_t packed = color_count;
    for (int vertex = 0; vertex < count; ++vertex)
        packed |= static_cast<std::int64_t>(colors[vertex]) << (4 * (vertex + 1));
    return packed;
}
