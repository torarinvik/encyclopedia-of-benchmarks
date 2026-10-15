/* Recursive height checks and subtree balance checks for an indexed tree. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;

std::int64_t tree_height(const std::int64_t *nodes, std::size_t node_count,
                         std::int64_t node) noexcept
{
    if (node == -1) return 0;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return -1;
    const auto index = static_cast<std::size_t>(node);
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        right < -1 || (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
    const auto left_height = tree_height(nodes, node_count, left);
    if (left_height < 0) return -1;
    const auto right_height = tree_height(nodes, node_count, right);
    if (right_height < 0) return -1;
    return 1 + (left_height > right_height ? left_height : right_height);
}

std::int64_t is_balanced(const std::int64_t *nodes, std::size_t node_count,
                         std::int64_t node) noexcept
{
    if (node == -1) return 1;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return -1;
    const auto index = static_cast<std::size_t>(node);
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        right < -1 || (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
    const auto left_height = tree_height(nodes, node_count, left);
    if (left_height < 0) return -1;
    const auto right_height = tree_height(nodes, node_count, right);
    if (right_height < 0) return -1;
    const auto difference = left_height >= right_height
        ? left_height - right_height : right_height - left_height;
    if (difference > 1) return 0;
    const auto left_balanced = is_balanced(nodes, node_count, left);
    if (left_balanced <= 0) return left_balanced;
    return is_balanced(nodes, node_count, right);
}
}

extern "C" std::int64_t balanced_binary_tree(const std::int64_t *nodes,
                                              std::size_t node_count,
                                              std::int64_t root_index) noexcept
{
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count)
        return -1;
    return is_balanced(nodes, node_count, root_index);
}
