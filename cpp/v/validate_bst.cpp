// Check strict BST bounds over a valid indexed binary tree.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;
constexpr std::int64_t value_min = -2147483647LL - 1;
constexpr std::int64_t value_max = 2147483647LL;

std::int64_t validate_subtree(const std::int64_t *nodes, std::size_t node_count,
                              std::int64_t node, bool has_lower, std::int64_t lower,
                              bool has_upper, std::int64_t upper) noexcept
{
    if (node == -1) return 1;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return -1;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (value < value_min || value > value_max ||
        left < -1 || (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        right < -1 || (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
    if ((has_lower && value <= lower) || (has_upper && value >= upper)) return 0;
    const auto left_result = validate_subtree(nodes, node_count, left, has_lower, lower, true, value);
    if (left_result <= 0) return left_result;
    return validate_subtree(nodes, node_count, right, true, value, has_upper, upper);
}
}

extern "C" std::int64_t validate_bst(const std::int64_t *nodes, std::size_t node_count,
                                     std::int64_t root_index) noexcept
{
    if (node_count > max_node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 1 : -1;
    if (nodes == nullptr || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    return validate_subtree(nodes, node_count, root_index, false, 0, false, 0);
}
