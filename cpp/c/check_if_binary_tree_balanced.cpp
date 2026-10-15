/* One-pass postorder height calculation, following the pinned Java method. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;

std::int64_t balanced_height(const std::int64_t *nodes, std::size_t count,
                             std::int64_t node, bool &balanced) noexcept
{
    if (node == -1 || !balanced) return 0;
    if (node < 0 || static_cast<std::uint64_t>(node) >= count) return -1;
    const auto index = static_cast<std::size_t>(node);
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && static_cast<std::uint64_t>(left) >= count) ||
        right < -1 || (right >= 0 && static_cast<std::uint64_t>(right) >= count)) return -1;
    const auto left_height = balanced_height(nodes, count, left, balanced);
    if (left_height < 0) return -1;
    const auto right_height = balanced_height(nodes, count, right, balanced);
    if (right_height < 0) return -1;
    const auto difference = left_height >= right_height
        ? left_height - right_height : right_height - left_height;
    if (difference > 1) balanced = false;
    return 1 + (left_height > right_height ? left_height : right_height);
}
}

extern "C" std::int64_t check_if_binary_tree_balanced(
    const std::int64_t *nodes, std::size_t node_count, std::int64_t root_index) noexcept
{
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count)
        return -1;
    bool balanced = true;
    const auto height = balanced_height(nodes, node_count, root_index, balanced);
    return height < 0 ? -1 : static_cast<std::int64_t>(balanced);
}
