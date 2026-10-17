#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 128;
constexpr std::size_t max_directed_edges = 2 * (max_nodes - 1);
constexpr std::size_t max_queries = 256;
constexpr std::size_t max_levels = 7;
constexpr std::size_t max_parseable_input_values = 771;

int dsu_find(int *parent, int node)
{
    int root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        const int parent_node = parent[node];
        parent[node] = root;
        node = parent_node;
    }
    return root;
}

int lca_query(int left, int right, const int *depth, const int *up, std::size_t levels)
{
    if (depth[left] < depth[right]) {
        const int temporary = left;
        left = right;
        right = temporary;
    }
    const unsigned difference = static_cast<unsigned>(depth[left] - depth[right]);
    for (std::size_t level = 0; level < levels; ++level) {
        if ((difference & (1u << level)) != 0u)
            left = up[static_cast<std::size_t>(left) * max_levels + level];
    }
    if (left == right) return left;
    for (std::size_t level = levels; level > 0; --level) {
        const std::size_t column = level - 1;
        const int left_ancestor = up[static_cast<std::size_t>(left) * max_levels + column];
        const int right_ancestor = up[static_cast<std::size_t>(right) * max_levels + column];
        if (left_ancestor != right_ancestor) {
            left = left_ancestor;
            right = right_ancestor;
        }
    }
    return up[static_cast<std::size_t>(left) * max_levels];
}
}

extern "C" std::int64_t lca_binary_lifting_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 4 || length > max_parseable_input_values) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const std::size_t node_count = static_cast<std::size_t>(input[0]);
    if (input[1] < 0 || input[1] >= static_cast<std::int64_t>(node_count)) return -1;
    const int root = static_cast<int>(input[1]);
    if (input[2] != static_cast<std::int64_t>(node_count - 1)) return -1;
    const std::size_t edge_count = node_count - 1;
    std::size_t cursor = 3;
    if (cursor + 2 * edge_count + 1 > length) return -1;

    int parent[max_nodes];
    int ranks[max_nodes] = {};
    int head[max_nodes];
    for (std::size_t node = 0; node < node_count; ++node) {
        parent[node] = static_cast<int>(node);
        head[node] = -1;
    }
    int to[max_directed_edges];
    int next[max_directed_edges];
    std::size_t directed_edge_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const std::int64_t left_value = input[cursor++];
        const std::int64_t right_value = input[cursor++];
        if (left_value < 0 || left_value >= static_cast<std::int64_t>(node_count) ||
            right_value < 0 || right_value >= static_cast<std::int64_t>(node_count) ||
            left_value == right_value) return -1;
        const int left = static_cast<int>(left_value);
        const int right = static_cast<int>(right_value);
        const int left_root = dsu_find(parent, left);
        const int right_root = dsu_find(parent, right);
        if (left_root == right_root) return -1;
        if (ranks[left_root] < ranks[right_root]) parent[left_root] = right_root;
        else if (ranks[left_root] > ranks[right_root]) parent[right_root] = left_root;
        else { parent[right_root] = left_root; ++ranks[left_root]; }

        to[directed_edge_count] = right;
        next[directed_edge_count] = head[left];
        head[left] = static_cast<int>(directed_edge_count++);
        to[directed_edge_count] = left;
        next[directed_edge_count] = head[right];
        head[right] = static_cast<int>(directed_edge_count++);
    }
    const int component = dsu_find(parent, 0);
    for (std::size_t node = 1; node < node_count; ++node)
        if (dsu_find(parent, static_cast<int>(node)) != component) return -1;

    const std::int64_t query_count_value = input[cursor++];
    if (query_count_value < 0 || query_count_value > static_cast<std::int64_t>(max_queries)) return -1;
    const std::size_t query_count = static_cast<std::size_t>(query_count_value);
    if (cursor + 2 * query_count != length) return -1;

    int depth[max_nodes];
    int ancestors[max_nodes];
    int queue[max_nodes];
    for (std::size_t node = 0; node < node_count; ++node) {
        depth[node] = -1;
        ancestors[node] = -1;
    }
    depth[root] = 0;
    ancestors[root] = root;
    std::size_t queue_head = 0;
    std::size_t queue_tail = 0;
    queue[queue_tail++] = root;
    while (queue_head < queue_tail) {
        const int node = queue[queue_head++];
        for (int edge = head[node]; edge >= 0; edge = next[edge]) {
            const int child = to[edge];
            if (child == ancestors[node]) continue;
            if (ancestors[child] >= 0) return -1;
            ancestors[child] = node;
            depth[child] = depth[node] + 1;
            queue[queue_tail++] = child;
        }
    }
    if (queue_tail != node_count) return -1;

    std::size_t levels = 0;
    while ((1u << levels) < node_count) ++levels;
    int up[max_nodes * max_levels] = {};
    for (std::size_t node = 0; node < node_count; ++node)
        up[node * max_levels] = ancestors[node];
    for (std::size_t level = 1; level < levels; ++level) {
        for (std::size_t node = 0; node < node_count; ++node) {
            const int previous = up[node * max_levels + level - 1];
            up[node * max_levels + level] = up[static_cast<std::size_t>(previous) * max_levels + level - 1];
        }
    }

    std::int64_t checksum = 0;
    for (std::size_t query = 0; query < query_count; ++query) {
        const std::int64_t left_value = input[cursor++];
        const std::int64_t right_value = input[cursor++];
        if (left_value < 0 || left_value >= static_cast<std::int64_t>(node_count) ||
            right_value < 0 || right_value >= static_cast<std::int64_t>(node_count)) return -1;
        const int ancestor = lca_query(static_cast<int>(left_value), static_cast<int>(right_value),
                                       depth, up, levels);
        checksum += static_cast<std::int64_t>(query + 1) * (static_cast<std::int64_t>(ancestor) + 1);
    }
    return checksum;
}
