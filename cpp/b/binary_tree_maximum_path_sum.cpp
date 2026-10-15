/* Recursive maximum-gain DFS with a best-path accumulator. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;
constexpr std::int64_t error_sentinel = -2000000000;

std::int64_t maximum_gain(const std::int64_t *nodes, std::size_t node_count,
                          std::int64_t node, std::int64_t &best_path) noexcept
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
    const auto left_gain = maximum_gain(nodes, node_count, left, best_path);
    if (left_gain == error_sentinel) return error_sentinel;
    const auto right_gain = maximum_gain(nodes, node_count, right, best_path);
    if (right_gain == error_sentinel) return error_sentinel;
    const auto positive_left = left_gain > 0 ? left_gain : 0;
    const auto positive_right = right_gain > 0 ? right_gain : 0;
    const auto through_node = value + positive_left + positive_right;
    if (through_node > best_path) best_path = through_node;
    return value + (positive_left > positive_right ? positive_left : positive_right);
}
}

extern "C" std::int64_t binary_tree_maximum_path_sum(const std::int64_t *nodes,
                                                      std::size_t node_count,
                                                      std::int64_t root_index) noexcept
{
    if (node_count == 0 || node_count > max_node_count || nodes == nullptr || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    std::int64_t best_path = -2147483648;
    const auto gain = maximum_gain(nodes, node_count, root_index, best_path);
    return gain == error_sentinel ? -1 : best_path;
}
