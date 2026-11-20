#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_vertices = 10;
constexpr std::int64_t max_edges = 20;
constexpr std::int64_t max_colors = 8;

bool is_forest(const std::int64_t *input, std::int64_t vertices,
               std::int64_t edges, std::int64_t edge_start,
               const std::array<bool, 20>& chosen,
               std::int64_t removed, std::int64_t added) noexcept {
    std::array<std::int64_t, 10> parent{};
    for (std::int64_t v = 0; v < vertices; ++v) parent[v] = v;
    for (std::int64_t edge = 0; edge < edges; ++edge) {
        if (edge != added && (!chosen[edge] || edge == removed)) continue;
        auto a = input[edge_start + 3 * edge];
        auto b = input[edge_start + 3 * edge + 1];
        while (parent[a] != a) a = parent[a];
        while (parent[b] != b) b = parent[b];
        if (a == b) return false;
        parent[b] = a;
    }
    return true;
}

bool within_quotas(const std::int64_t *input, std::int64_t colors,
                   std::int64_t edges, std::int64_t edge_start,
                   const std::array<bool, 20>& chosen,
                   std::int64_t removed, std::int64_t added) noexcept {
    std::array<std::int64_t, 8> counts{};
    for (std::int64_t edge = 0; edge < edges; ++edge) {
        if (edge != added && (!chosen[edge] || edge == removed)) continue;
        const auto color = input[edge_start + 3 * edge + 2];
        if (++counts[color] > input[3 + color]) return false;
    }
    return true;
}
}

extern "C" std::int64_t matroid_intersection(const std::int64_t *input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > 72) return -1;
    const auto vertices = input[0];
    const auto edges = input[1];
    const auto colors = input[2];
    if (vertices < 1 || vertices > max_vertices || edges < 0 || edges > max_edges
            || colors < 1 || colors > max_colors
            || length != static_cast<std::size_t>(3 + colors + 3 * edges)) return -1;
    for (std::int64_t color = 0; color < colors; ++color) {
        if (input[3 + color] < 0 || input[3 + color] > max_edges) return -1;
    }
    const auto edge_start = 3 + colors;
    for (std::int64_t edge = 0; edge < edges; ++edge) {
        const auto u = input[edge_start + 3 * edge];
        const auto v = input[edge_start + 3 * edge + 1];
        const auto color = input[edge_start + 3 * edge + 2];
        if (u < 0 || u >= vertices || v < 0 || v >= vertices
                || color < 0 || color >= colors) return -1;
    }

    std::array<bool, 20> chosen{};
    for (;;) {
        std::array<std::int64_t, 20> predecessor{};
        std::array<std::int64_t, 20> queue{};
        for (std::int64_t edge = 0; edge < edges; ++edge) predecessor[edge] = -2;
        std::int64_t head = 0, tail = 0;
        for (std::int64_t edge = 0; edge < edges; ++edge) {
            if (!chosen[edge] && is_forest(input, vertices, edges, edge_start,
                                           chosen, -1, edge)) {
                predecessor[edge] = -1;
                queue[tail++] = edge;
            }
        }
        std::int64_t terminal = -1;
        while (head < tail && terminal < 0) {
            const auto current = queue[head++];
            if (!chosen[current]) {
                if (within_quotas(input, colors, edges, edge_start,
                                  chosen, -1, current)) {
                    terminal = current;
                    break;
                }
                for (std::int64_t inside = 0; inside < edges; ++inside) {
                    if (chosen[inside] && predecessor[inside] == -2
                            && within_quotas(input, colors, edges, edge_start,
                                             chosen, inside, current)) {
                        predecessor[inside] = current;
                        queue[tail++] = inside;
                    }
                }
            } else {
                for (std::int64_t outside = 0; outside < edges; ++outside) {
                    if (!chosen[outside] && predecessor[outside] == -2
                            && is_forest(input, vertices, edges, edge_start,
                                         chosen, current, outside)) {
                        predecessor[outside] = current;
                        queue[tail++] = outside;
                    }
                }
            }
        }
        if (terminal < 0) break;
        for (auto edge = terminal; edge >= 0; edge = predecessor[edge]) {
            chosen[edge] = !chosen[edge];
        }
    }
    std::int64_t answer = 0;
    for (std::int64_t edge = 0; edge < edges; ++edge) answer += chosen[edge];
    return answer;
}
