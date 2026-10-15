/* Bottom-up DFS heights over the source's undirected adjacency-list tree. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 1023;
constexpr std::size_t max_arcs = 2 * (max_nodes - 1);

std::int64_t dfs_height(std::size_t node, std::size_t count, const std::int64_t *head,
                        const std::int64_t *to, const std::int64_t *next,
                        std::uint8_t *visited, std::int64_t *dp, std::size_t &reached)
{
    visited[node] = 1;
    ++reached;
    std::int64_t child_height = 1;
    for (auto arc = head[node]; arc >= 0; arc = next[static_cast<std::size_t>(arc)]) {
        const auto child = static_cast<std::size_t>(to[static_cast<std::size_t>(arc)]);
        if (!visited[child]) {
            if (dfs_height(child, count, head, to, next, visited, dp, reached) < 0) return -1;
            if (dp[child] + 1 > child_height) child_height = dp[child] + 1;
        }
    }
    dp[node] = child_height;
    (void)count;
    return child_height;
}
}

extern "C" std::int64_t tree_height(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || values[0] < 1 || values[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 2 * (count - 1)) return -1;
    std::int64_t head[max_nodes + 1], to[max_arcs], next[max_arcs], dp[max_nodes + 1];
    std::uint8_t visited[max_nodes + 1]{};
    for (std::size_t node = 0; node <= count; ++node) head[node] = -1;
    std::size_t arcs = 0;
    for (std::size_t edge = 0; edge + 1 < count; ++edge) {
        const auto a = values[1 + 2 * edge], b = values[2 + 2 * edge];
        if (a < 1 || b < 1 || a > static_cast<std::int64_t>(count) ||
            b > static_cast<std::int64_t>(count) || a == b) return -1;
        to[arcs] = b; next[arcs] = head[a]; head[a] = static_cast<std::int64_t>(arcs++);
        to[arcs] = a; next[arcs] = head[b]; head[b] = static_cast<std::int64_t>(arcs++);
    }
    std::size_t reached = 0;
    const auto result = dfs_height(1, count, head, to, next, visited, dp, reached);
    return result < 0 || reached != count ? -1 : result;
}
