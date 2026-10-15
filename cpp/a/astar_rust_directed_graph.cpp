#include <cstddef>
#include <cstdint>
#include <limits>

static void put_i64_le(std::int64_t value, std::uint8_t *output, std::size_t offset) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t astar_rust_directed_graph(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 4) return -1;
    const auto vertex_count = input[0], edge_count = input[1];
    if (vertex_count < 1 || vertex_count > 32 || edge_count < 0 || edge_count > 128) return -1;
    if (length != 4 + static_cast<std::size_t>(vertex_count) + 3 * static_cast<std::size_t>(edge_count)) return -1;
    const auto start = input[2], goal = input[3];
    if (start < 0 || start >= vertex_count || goal < 0 || goal >= vertex_count) return -1;
    const auto *heuristic = input + 4;
    const auto *edges = heuristic + vertex_count;
    for (std::int64_t v = 0; v < vertex_count; ++v) if (heuristic[v] < 0 || heuristic[v] > 1000000) return -1;
    if (heuristic[goal] != 0) return -1;
    for (std::int64_t e = 0; e < edge_count; ++e) {
        const auto from = edges[3 * e], to = edges[3 * e + 1], weight = edges[3 * e + 2];
        if (from < 0 || from >= vertex_count || to < 0 || to >= vertex_count || weight < 0 || weight > 1000000) return -1;
        if (heuristic[from] > weight + heuristic[to]) return -1;
    }
    constexpr auto infinity = std::numeric_limits<std::int64_t>::max();
    std::int64_t distance[32], parent[32]; bool closed[32]{};
    for (std::int64_t v = 0; v < vertex_count; ++v) { distance[v] = infinity; parent[v] = -1; }
    distance[start] = 0;
    for (std::int64_t step = 0; step < vertex_count; ++step) {
        std::int64_t current = -1;
        for (std::int64_t v = 0; v < vertex_count; ++v) {
            if (closed[v] || distance[v] == infinity) continue;
            if (current < 0 || distance[v] + heuristic[v] < distance[current] + heuristic[current] ||
                (distance[v] + heuristic[v] == distance[current] + heuristic[current] &&
                 (distance[v] < distance[current] || (distance[v] == distance[current] && v < current)))) current = v;
        }
        if (current < 0) break;
        if (current == goal) break;
        closed[current] = true;
        for (std::int64_t e = 0; e < edge_count; ++e) if (edges[3 * e] == current) {
            const auto next = edges[3 * e + 1], candidate = distance[current] + edges[3 * e + 2];
            if (!closed[next] && candidate < distance[next]) { distance[next] = candidate; parent[next] = current; }
        }
    }
    if (distance[goal] == infinity) return 0;
    std::int64_t reversed[32], path_length = 0, current = goal;
    while (path_length < vertex_count) {
        reversed[path_length++] = current;
        if (current == start) break;
        current = parent[current]; if (current < 0) return -1;
    }
    if (reversed[path_length - 1] != start) return -1;
    const auto required = 8 * (static_cast<std::size_t>(path_length) + 2);
    if (!output || capacity < required) return -2;
    put_i64_le(distance[goal], output, 0); put_i64_le(path_length, output, 8);
    for (std::int64_t i = 0; i < path_length; ++i) put_i64_le(reversed[path_length - 1 - i], output, 16 + static_cast<std::size_t>(i) * 8);
    return static_cast<std::int64_t>(required);
}
