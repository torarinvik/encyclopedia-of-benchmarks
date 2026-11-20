#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 6;
constexpr std::size_t max_edges = 6;
constexpr std::size_t max_length = 15;
constexpr std::int64_t signature_base = 262144;

bool free_color(std::size_t vertex, std::int64_t color, std::size_t vertices,
                const std::array<int, 36>& edge_at,
                const std::array<std::int64_t, 6>& colors) {
    for (std::size_t other = 0; other < vertices; ++other) {
        const int edge = edge_at[vertex * max_vertices + other];
        if (edge >= 0 && colors[static_cast<std::size_t>(edge)] == color) return false;
    }
    return true;
}
}

extern "C" std::int64_t misra_gries_edge_coloring(const std::int64_t* input,
                                                  std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > 6 || input[1] < 0 || input[1] > 6) return -1;
    const auto vertices = static_cast<std::size_t>(input[0]);
    const auto edge_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * edge_count) return -1;

    std::array<std::size_t, 6> left{}, right{};
    std::array<int, 36> edge_at{};
    edge_at.fill(-1);
    std::array<std::size_t, 6> degree{};
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto a = input[2 + 2 * edge], b = input[3 + 2 * edge];
        if (a < 0 || b < 0 || a >= static_cast<std::int64_t>(vertices)
            || b >= static_cast<std::int64_t>(vertices) || a == b) return -1;
        const auto u = static_cast<std::size_t>(a < b ? a : b);
        const auto v = static_cast<std::size_t>(a < b ? b : a);
        if (edge_at[u * max_vertices + v] >= 0) return -1;
        left[edge] = u; right[edge] = v;
        edge_at[u * max_vertices + v] = edge_at[v * max_vertices + u] = static_cast<int>(edge);
        ++degree[u]; ++degree[v];
    }
    std::size_t delta = 0;
    for (auto d : degree) if (d > delta) delta = d;
    const std::size_t palette = edge_count == 0 ? 0 : delta + 1;
    std::array<std::int64_t, 6> colors{};
    colors.fill(-1);

    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto center = left[edge];
        std::array<std::size_t, 6> fan{};
        std::size_t fan_count = 1;
        fan[0] = right[edge];
        for (;;) {
            const auto tail = fan[fan_count - 1];
            bool extended = false;
            for (std::size_t neighbor = 0; neighbor < vertices; ++neighbor) {
                const int candidate = edge_at[center * max_vertices + neighbor];
                if (candidate < 0 || colors[static_cast<std::size_t>(candidate)] < 0) continue;
                bool present = false;
                for (std::size_t i = 0; i < fan_count; ++i) present |= fan[i] == neighbor;
                if (present || !free_color(tail, colors[static_cast<std::size_t>(candidate)],
                                           vertices, edge_at, colors)) continue;
                fan[fan_count++] = neighbor;
                extended = true;
                break;
            }
            if (!extended) break;
        }
        std::int64_t color_c = 0, color_d = 0;
        while (color_c < static_cast<std::int64_t>(palette)
               && !free_color(center, color_c, vertices, edge_at, colors)) ++color_c;
        while (color_d < static_cast<std::int64_t>(palette)
               && !free_color(fan[fan_count - 1], color_d, vertices, edge_at, colors)) ++color_d;
        if (color_c >= static_cast<std::int64_t>(palette)
            || color_d >= static_cast<std::int64_t>(palette)) return -1;

        std::array<std::size_t, 6> path{};
        std::size_t path_count = 0, current = center;
        std::int64_t wanted = color_d;
        std::array<bool, 6> visited{};
        visited[current] = true;
        for (std::size_t step = 0; step < vertices; ++step) {
            int path_edge = -1;
            std::size_t next = 0;
            for (std::size_t neighbor = 0; neighbor < vertices; ++neighbor) {
                const int candidate = edge_at[current * max_vertices + neighbor];
                if (candidate >= 0 && colors[static_cast<std::size_t>(candidate)] == wanted) {
                    path_edge = candidate; next = neighbor; break;
                }
            }
            if (path_edge < 0 || visited[next]) break;
            path[path_count++] = static_cast<std::size_t>(path_edge);
            visited[next] = true;
            current = next;
            wanted = wanted == color_d ? color_c : color_d;
        }
        for (std::size_t i = 0; i < path_count; ++i) {
            auto& color = colors[path[i]];
            color = color == color_d ? color_c : color_d;
        }

        std::size_t prefix_end = fan_count;
        for (std::size_t i = 0; i < fan_count; ++i)
            if (free_color(fan[i], color_d, vertices, edge_at, colors)) { prefix_end = i; break; }
        if (prefix_end == fan_count) return -1;
        std::array<std::int64_t, 6> shifted{};
        for (std::size_t i = 0; i < prefix_end; ++i)
            shifted[i] = colors[static_cast<std::size_t>(edge_at[center * max_vertices + fan[i + 1]])];
        for (std::size_t i = 0; i < prefix_end; ++i)
            colors[static_cast<std::size_t>(edge_at[center * max_vertices + fan[i]])] = shifted[i];
        colors[static_cast<std::size_t>(edge_at[center * max_vertices + fan[prefix_end]])] = color_d;
    }

    std::int64_t signature = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge)
        signature |= colors[edge] << (3 * edge);
    return static_cast<std::int64_t>(palette) * signature_base + signature;
}
