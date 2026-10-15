#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_NODES = 256;
constexpr std::size_t MAX_QUERIES = 1024;
constexpr std::size_t MAX_ARCS = 510;
constexpr std::size_t LOG_LEVELS = 9;
}

extern "C" std::int64_t lowest_common_ancestor_binary_lifting(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 4 || input[0] < 1 || input[0] > static_cast<std::int64_t>(MAX_NODES)) return -1;
    const auto node_count = static_cast<std::size_t>(input[0]);
    if (input[1] < 0 || input[1] >= static_cast<std::int64_t>(node_count) ||
        input[2] != static_cast<std::int64_t>(node_count - 1) || input[3] < 0 || input[3] > static_cast<std::int64_t>(MAX_QUERIES)) return -1;
    const auto edge_count = static_cast<std::size_t>(input[2]);
    const auto query_count = static_cast<std::size_t>(input[3]);
    const std::size_t query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    const auto root = static_cast<std::size_t>(input[1]);

    int head[MAX_NODES], arc_to[MAX_ARCS], arc_next[MAX_ARCS];
    std::int64_t parent[MAX_NODES];
    std::size_t depth[MAX_NODES] = {}, up[LOG_LEVELS][MAX_NODES] = {}, stack[MAX_NODES];
    for (std::size_t node = 0; node < node_count; ++node) { head[node] = -1; parent[node] = -2; }
    std::size_t arc_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left = input[4 + 2 * edge], right = input[5 + 2 * edge];
        if (left < 0 || left >= static_cast<std::int64_t>(node_count) || right < 0 || right >= static_cast<std::int64_t>(node_count) || left == right) return -1;
        arc_to[arc_count] = static_cast<int>(right); arc_next[arc_count] = head[static_cast<std::size_t>(left)]; head[static_cast<std::size_t>(left)] = static_cast<int>(arc_count++);
        arc_to[arc_count] = static_cast<int>(left); arc_next[arc_count] = head[static_cast<std::size_t>(right)]; head[static_cast<std::size_t>(right)] = static_cast<int>(arc_count++);
    }
    for (std::size_t query = 0; query < query_count; ++query)
        for (std::size_t side = 0; side < 2; ++side)
            if (input[query_offset + 2 * query + side] < 0 || input[query_offset + 2 * query + side] >= static_cast<std::int64_t>(node_count)) return -1;

    std::size_t top = 0, reached = 0;
    parent[root] = -1; up[0][root] = root; stack[top++] = root;
    while (top != 0) {
        const auto node = stack[--top]; ++reached;
        for (int arc = head[node]; arc >= 0; arc = arc_next[arc]) {
            const auto neighbor = static_cast<std::size_t>(arc_to[arc]);
            if (static_cast<std::int64_t>(neighbor) == parent[node]) continue;
            if (parent[neighbor] != -2) return -1;
            parent[neighbor] = static_cast<std::int64_t>(node);
            depth[neighbor] = depth[node] + 1; up[0][neighbor] = node; stack[top++] = neighbor;
        }
    }
    if (reached != node_count) return -1;
    if (output_capacity < query_count || (query_count != 0 && output == nullptr)) return -2;
    for (std::size_t level = 1; level < LOG_LEVELS; ++level)
        for (std::size_t node = 0; node < node_count; ++node)
            up[level][node] = up[level - 1][up[level - 1][node]];
    for (std::size_t query = 0; query < query_count; ++query) {
        auto u = static_cast<std::size_t>(input[query_offset + 2 * query]);
        auto v = static_cast<std::size_t>(input[query_offset + 2 * query + 1]);
        if (depth[u] < depth[v]) { const auto temp = u; u = v; v = temp; }
        const auto difference = depth[u] - depth[v];
        for (std::size_t level = 0; level < LOG_LEVELS; ++level)
            if ((difference & (static_cast<std::size_t>(1) << level)) != 0) u = up[level][u];
        if (u != v) {
            for (std::size_t level = LOG_LEVELS; level-- > 0;)
                if (up[level][u] != up[level][v]) { u = up[level][u]; v = up[level][v]; }
            u = up[0][u];
        }
        output[query] = static_cast<std::uint8_t>(u);
    }
    return static_cast<std::int64_t>(query_count);
}
