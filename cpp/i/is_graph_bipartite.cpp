// BFS two-coloring for a bounded undirected graph.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 64;
constexpr std::size_t MAX_EDGES = 256;
constexpr std::int64_t INVALID_RESULT = -1;
}

extern "C" std::int64_t is_graph_bipartite(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 2 + 2 * MAX_EDGES) return INVALID_RESULT;
    const auto vertex_count_raw = values[0];
    const auto edge_count_raw = values[1];
    if (vertex_count_raw < 0 || vertex_count_raw > static_cast<std::int64_t>(MAX_VERTICES) ||
        edge_count_raw < 0 || edge_count_raw > static_cast<std::int64_t>(MAX_EDGES) ||
        length != 2 + 2 * static_cast<std::size_t>(edge_count_raw)) return INVALID_RESULT;
    const auto vertex_count = static_cast<std::size_t>(vertex_count_raw);
    const auto edge_count = static_cast<std::size_t>(edge_count_raw);

    int head[MAX_VERTICES];
    int to[2 * MAX_EDGES];
    int next[2 * MAX_EDGES];
    int side[MAX_VERTICES];
    int queue[MAX_VERTICES];
    for (std::size_t vertex = 0; vertex < vertex_count; ++vertex) {
        head[vertex] = -1;
        side[vertex] = -1;
    }
    int arc_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto u_raw = values[2 + 2 * edge];
        const auto v_raw = values[3 + 2 * edge];
        if (u_raw < 1 || u_raw > vertex_count_raw || v_raw < 1 || v_raw > vertex_count_raw)
            return INVALID_RESULT;
        const int u = static_cast<int>(u_raw - 1);
        const int v = static_cast<int>(v_raw - 1);
        to[arc_count] = v; next[arc_count] = head[u]; head[u] = arc_count++;
        to[arc_count] = u; next[arc_count] = head[v]; head[v] = arc_count++;
    }

    int bipartite = 1;
    for (std::size_t start = 0; start < vertex_count; ++start) {
        if (side[start] != -1) continue;
        std::size_t queue_head = 0, queue_tail = 0;
        queue[queue_tail++] = static_cast<int>(start);
        side[start] = 0;
        while (queue_head < queue_tail) {
            const int current = queue[queue_head++];
            for (int arc = head[current]; arc != -1; arc = next[arc]) {
                const int neighbor = to[arc];
                if (side[neighbor] == -1) {
                    side[neighbor] = side[current] ^ 1;
                    queue[queue_tail++] = neighbor;
                } else if (side[neighbor] == side[current]) {
                    bipartite = 0;
                }
            }
        }
    }
    return bipartite;
}
