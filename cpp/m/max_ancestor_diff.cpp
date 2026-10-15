/* Recursive path-minimum/path-maximum search for maximum ancestor difference. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;

std::int64_t visit(const std::int64_t *nodes, std::size_t node_count, std::int64_t node,
                   std::int64_t path_min, std::int64_t path_max) noexcept
{
    if (node == -1) return 0;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return -1;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    if (value < -100000 || value > 100000) return -1;
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (left < -1 || (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        right < -1 || (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
    auto best = path_min >= value ? path_min - value : value - path_min;
    const auto high_difference = path_max >= value ? path_max - value : value - path_max;
    if (high_difference > best) best = high_difference;
    const auto low = value < path_min ? value : path_min;
    const auto high = value > path_max ? value : path_max;
    const auto left_best = visit(nodes, node_count, left, low, high);
    if (left_best < 0) return -1;
    const auto right_best = visit(nodes, node_count, right, low, high);
    if (right_best < 0) return -1;
    if (left_best > best) best = left_best;
    if (right_best > best) best = right_best;
    return best;
}
}

extern "C" std::int64_t max_ancestor_diff(const std::int64_t *nodes,
                                           std::size_t node_count,
                                           std::int64_t root_index) noexcept
{
    if (node_count == 0 || node_count > max_node_count || nodes == nullptr || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    const auto root_value = nodes[3 * static_cast<std::size_t>(root_index)];
    if (root_value < -100000 || root_value > 100000) return -1;
    return visit(nodes, node_count, root_index, root_value, root_value);
}
