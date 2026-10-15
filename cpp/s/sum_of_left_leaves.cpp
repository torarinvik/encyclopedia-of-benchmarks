/* Recursively sum leaf values whose incoming edge is a left-child edge. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;
constexpr std::int64_t error_sentinel = -2000000000;

std::int64_t visit(const std::int64_t *nodes, std::size_t node_count,
                   std::int64_t node, bool is_left) noexcept
{
    if (node == -1) return 0;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return error_sentinel;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (value < -1000 || value > 1000 || left < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) || right < -1 ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return error_sentinel;
    if (left == -1 && right == -1) return is_left ? value : 0;
    const auto left_sum = visit(nodes, node_count, left, true);
    if (left_sum == error_sentinel) return error_sentinel;
    const auto right_sum = visit(nodes, node_count, right, false);
    if (right_sum == error_sentinel) return error_sentinel;
    return left_sum + right_sum;
}
}

extern "C" std::int64_t sum_of_left_leaves(const std::int64_t *nodes,
                                           std::size_t node_count,
                                           std::int64_t root_index) noexcept
{
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count)
        return -1;
    const auto result = visit(nodes, node_count, root_index, false);
    return result == error_sentinel ? -1 : result;
}
