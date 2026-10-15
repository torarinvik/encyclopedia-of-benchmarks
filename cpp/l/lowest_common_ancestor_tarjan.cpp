#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxNodeCount = 256;
constexpr std::size_t MaxQueryCount = 1024;
constexpr std::size_t MaxAdjacencyCount = 2 * (MaxNodeCount - 1);
constexpr std::size_t MaxQueryAdjacencyCount = 2 * MaxQueryCount;

std::size_t find_root(std::size_t parent[MaxNodeCount], std::size_t node) noexcept
{
    auto root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        const auto next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

void unite(std::size_t parent[MaxNodeCount], std::uint8_t rank[MaxNodeCount],
           std::size_t left, std::size_t right) noexcept
{
    auto left_root = find_root(parent, left);
    auto right_root = find_root(parent, right);
    if (left_root == right_root) return;
    if (rank[left_root] < rank[right_root]) parent[left_root] = right_root;
    else if (rank[left_root] > rank[right_root]) parent[right_root] = left_root;
    else { parent[right_root] = left_root; ++rank[left_root]; }
}
}

extern "C" std::int64_t lowest_common_ancestor_tarjan(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 4 || input[0] < 1 || input[0] > static_cast<std::int64_t>(MaxNodeCount))
        return -1;
    const auto node_count = static_cast<std::size_t>(input[0]);
    if (input[1] < 0 || input[1] >= static_cast<std::int64_t>(node_count) || input[2] < 0 ||
        input[2] != static_cast<std::int64_t>(node_count - 1) || input[3] < 0 ||
        input[3] > static_cast<std::int64_t>(MaxQueryCount)) return -1;
    const auto root = static_cast<std::size_t>(input[1]);
    const auto edge_count = static_cast<std::size_t>(input[2]);
    const auto query_count = static_cast<std::size_t>(input[3]);
    if (length != 4 + 2 * edge_count + 2 * query_count) return -1;

    std::size_t validation_parent[MaxNodeCount], dsu_parent[MaxNodeCount];
    std::size_t ancestor[MaxNodeCount];
    std::uint8_t validation_rank[MaxNodeCount] = {}, dsu_rank[MaxNodeCount] = {};
    std::int64_t edge_head[MaxNodeCount], edge_to[MaxAdjacencyCount], edge_next[MaxAdjacencyCount];
    std::int64_t query_head[MaxNodeCount], query_to[MaxQueryAdjacencyCount];
    std::int64_t query_next[MaxQueryAdjacencyCount], query_id[MaxQueryAdjacencyCount];
    std::int64_t answers[MaxQueryCount], tree_parent[MaxNodeCount], cursor[MaxNodeCount];
    bool visited[MaxNodeCount] = {}, finished[MaxNodeCount] = {};
    std::size_t stack[MaxNodeCount];
    for (std::size_t node = 0; node < node_count; ++node) {
        validation_parent[node] = node;
        dsu_parent[node] = node;
        ancestor[node] = node;
        edge_head[node] = -1;
        query_head[node] = -1;
        tree_parent[node] = -1;
    }
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto left_arg = input[4 + 2 * edge], right_arg = input[5 + 2 * edge];
        if (left_arg < 0 || right_arg < 0 || left_arg >= static_cast<std::int64_t>(node_count) ||
            right_arg >= static_cast<std::int64_t>(node_count) || left_arg == right_arg) return -1;
        const auto left = static_cast<std::size_t>(left_arg), right = static_cast<std::size_t>(right_arg);
        if (find_root(validation_parent, left) == find_root(validation_parent, right)) return -1;
        unite(validation_parent, validation_rank, left, right);
        const auto forward = 2 * edge, reverse = forward + 1;
        edge_to[forward] = static_cast<std::int64_t>(right);
        edge_next[forward] = edge_head[left];
        edge_head[left] = static_cast<std::int64_t>(forward);
        edge_to[reverse] = static_cast<std::int64_t>(left);
        edge_next[reverse] = edge_head[right];
        edge_head[right] = static_cast<std::int64_t>(reverse);
    }
    for (std::size_t node = 0; node < node_count; ++node)
        if (find_root(validation_parent, node) != find_root(validation_parent, root)) return -1;
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto left_arg = input[4 + 2 * edge_count + 2 * query];
        const auto right_arg = input[5 + 2 * edge_count + 2 * query];
        if (left_arg < 0 || right_arg < 0 || left_arg >= static_cast<std::int64_t>(node_count) ||
            right_arg >= static_cast<std::int64_t>(node_count)) return -1;
        const auto left = static_cast<std::size_t>(left_arg), right = static_cast<std::size_t>(right_arg);
        const auto first = 2 * query, second = first + 1;
        query_to[first] = static_cast<std::int64_t>(right);
        query_id[first] = static_cast<std::int64_t>(query);
        query_next[first] = query_head[left];
        query_head[left] = static_cast<std::int64_t>(first);
        query_to[second] = static_cast<std::int64_t>(left);
        query_id[second] = static_cast<std::int64_t>(query);
        query_next[second] = query_head[right];
        query_head[right] = static_cast<std::int64_t>(second);
    }
    if (query_count > output_capacity || (query_count != 0 && output == nullptr)) return -2;

    std::size_t top = 0;
    stack[top++] = root;
    visited[root] = true;
    cursor[root] = edge_head[root];
    while (top != 0) {
        const auto node = stack[top - 1];
        const auto edge = cursor[node];
        if (edge >= 0) {
            cursor[node] = edge_next[static_cast<std::size_t>(edge)];
            const auto child = static_cast<std::size_t>(edge_to[static_cast<std::size_t>(edge)]);
            if (static_cast<std::int64_t>(child) == tree_parent[node]) continue;
            if (visited[child]) return -1;
            visited[child] = true;
            tree_parent[child] = static_cast<std::int64_t>(node);
            cursor[child] = edge_head[child];
            stack[top++] = child;
            continue;
        }
        finished[node] = true;
        for (auto item = query_head[node]; item >= 0; item = query_next[static_cast<std::size_t>(item)]) {
            const auto index = static_cast<std::size_t>(item);
            const auto other = static_cast<std::size_t>(query_to[index]);
            if (finished[other]) answers[static_cast<std::size_t>(query_id[index])] =
                static_cast<std::int64_t>(ancestor[find_root(dsu_parent, other)]);
        }
        --top;
        if (tree_parent[node] >= 0) {
            const auto parent = static_cast<std::size_t>(tree_parent[node]);
            unite(dsu_parent, dsu_rank, parent, node);
            ancestor[find_root(dsu_parent, parent)] = parent;
        }
    }
    for (std::size_t query = 0; query < query_count; ++query) output[query] = static_cast<std::uint8_t>(answers[query]);
    return static_cast<std::int64_t>(query_count);
}
