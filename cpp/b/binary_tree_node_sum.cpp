// Sum every node reachable from the root of a bounded indexed binary tree.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 900;
constexpr std::int64_t invalid_result = -9000000000000000000LL;

std::int64_t sum_visit(const std::int64_t *nodes, std::size_t node_count,
                       std::int64_t node, std::size_t depth) noexcept {
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count || depth >= node_count)
        return invalid_result;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (value < -1000000000 || value > 1000000000 || left < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) || right < -1 ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return invalid_result;
    const auto left_sum = left == -1 ? 0 : sum_visit(nodes, node_count, left, depth + 1);
    if (left_sum == invalid_result) return invalid_result;
    const auto right_sum = right == -1 ? 0 : sum_visit(nodes, node_count, right, depth + 1);
    if (right_sum == invalid_result) return invalid_result;
    return value + left_sum + right_sum;
}
}

extern "C" std::int64_t binary_tree_node_sum(const std::int64_t *nodes,
    std::size_t node_count, std::int64_t root_index) noexcept {
    if (nodes == nullptr || node_count == 0 || node_count > max_node_count || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return invalid_result;
    return sum_visit(nodes, node_count, root_index, 0);
}
