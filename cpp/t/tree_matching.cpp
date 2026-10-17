/* Two-state maximum-weight matching DP on the supplied undirected tree. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 64;
constexpr std::size_t max_input_values = 2 + 3 * (max_nodes - 1);

void matching_dp(std::size_t node, int parent, std::size_t count,
                 const bool adjacent[max_nodes][max_nodes],
                 const std::int64_t weight[max_nodes][max_nodes],
                 bool visited[max_nodes], int parent_of[max_nodes],
                 std::int64_t without_edge[max_nodes],
                 std::int64_t with_edge[max_nodes], std::size_t &reached)
{
    visited[node] = true;
    parent_of[node] = parent;
    ++reached;
    std::int64_t base = 0;
    for (std::size_t child = 0; child < count; ++child) {
        if (adjacent[node][child] && static_cast<int>(child) != parent && !visited[child]) {
            matching_dp(child, static_cast<int>(node), count, adjacent, weight, visited,
                        parent_of, without_edge, with_edge, reached);
            base += without_edge[child] > with_edge[child]
                        ? without_edge[child] : with_edge[child];
        }
    }
    without_edge[node] = base;
    with_edge[node] = 0;
    for (std::size_t child = 0; child < count; ++child) {
        if (parent_of[child] == static_cast<int>(node)) {
            const auto child_best = without_edge[child] > with_edge[child]
                                        ? without_edge[child] : with_edge[child];
            const auto candidate = base - child_best + without_edge[child] + weight[node][child];
            if (candidate > with_edge[node]) with_edge[node] = candidate;
        }
    }
}
}

extern "C" std::int64_t tree_matching(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > max_input_values || values[0] < 1 || values[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != 2 + 3 * (count - 1) || values[1] < 0 || values[1] >= static_cast<std::int64_t>(count)) return -1;
    bool adjacent[max_nodes][max_nodes]{};
    std::int64_t weight[max_nodes][max_nodes]{};
    for (std::size_t edge = 0; edge < count - 1; ++edge) {
        const auto a_value = values[2 + 3 * edge], b_value = values[3 + 3 * edge], w = values[4 + 3 * edge];
        if (a_value < 0 || b_value < 0 || a_value >= static_cast<std::int64_t>(count) ||
            b_value >= static_cast<std::int64_t>(count) || a_value == b_value || w < 0 || w > 1000) return -1;
        const auto a = static_cast<std::size_t>(a_value), b = static_cast<std::size_t>(b_value);
        if (adjacent[a][b]) return -1;
        adjacent[a][b] = adjacent[b][a] = true;
        weight[a][b] = weight[b][a] = w;
    }
    bool visited[max_nodes]{};
    int parent_of[max_nodes];
    std::int64_t without_edge[max_nodes]{}, with_edge[max_nodes]{};
    for (std::size_t node = 0; node < count; ++node) parent_of[node] = -2;
    std::size_t reached = 0;
    matching_dp(static_cast<std::size_t>(values[1]), -1, count, adjacent, weight, visited,
                parent_of, without_edge, with_edge, reached);
    if (reached != count) return -1;
    const auto root = static_cast<std::size_t>(values[1]);
    return without_edge[root] > with_edge[root] ? without_edge[root] : with_edge[root];
}
