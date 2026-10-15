/* Count coin transfers in a valid indexed binary tree. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 100;

std::int64_t absolute_i64(std::int64_t value) noexcept
{
    return value < 0 ? -value : value;
}

std::int64_t analyze(const std::int64_t *nodes, std::int64_t node,
                     std::int64_t &moves) noexcept
{
    if (node == -1) return 1;
    const auto index = static_cast<std::size_t>(node);
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    const auto left_excess = analyze(nodes, left, moves);
    const auto right_excess = analyze(nodes, right, moves);
    moves += absolute_i64(1 - left_excess) + absolute_i64(1 - right_excess);
    return nodes[3 * index] + left_excess + right_excess - 2;
}
}

extern "C" std::int64_t distribute_coins(const std::int64_t *nodes,
                                          std::size_t node_count,
                                          std::int64_t root_index) noexcept
{
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count)
        return -1;

    std::int64_t parent[max_node_count];
    std::size_t stack[max_node_count];
    bool seen[max_node_count]{};
    for (std::size_t node = 0; node < node_count; ++node) parent[node] = -1;

    std::int64_t coin_total = 0;
    for (std::size_t node = 0; node < node_count; ++node) {
        const auto value = nodes[3 * node];
        if (value < 0 || value > 100) return -1;
        coin_total += value;
        for (std::size_t edge = 1; edge <= 2; ++edge) {
            const auto child = nodes[3 * node + edge];
            if (child < -1 || (child >= 0 && static_cast<std::uint64_t>(child) >= node_count)) return -1;
            if (child >= 0) {
                const auto child_index = static_cast<std::size_t>(child);
                if (parent[child_index] != -1) return -1;
                parent[child_index] = static_cast<std::int64_t>(node);
            }
        }
    }
    if (coin_total != static_cast<std::int64_t>(node_count)) return -1;
    const auto root = static_cast<std::size_t>(root_index);
    if (parent[root] != -1) return -1;
    for (std::size_t node = 0; node < node_count; ++node)
        if (node != root && parent[node] == -1) return -1;

    std::size_t top = 0, reached = 0;
    stack[top++] = root;
    while (top > 0) {
        const auto node = stack[--top];
        if (seen[node]) return -1;
        seen[node] = true;
        ++reached;
        for (std::size_t edge = 1; edge <= 2; ++edge) {
            const auto child = nodes[3 * node + edge];
            if (child >= 0) stack[top++] = static_cast<std::size_t>(child);
        }
    }
    if (reached != node_count) return -1;

    std::int64_t moves = 0;
    (void)analyze(nodes, root_index, moves);
    return moves;
}
