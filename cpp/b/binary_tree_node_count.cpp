// Count nodes reachable from the root of a bounded indexed binary tree.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 900;
constexpr std::int64_t invalid_result = -9000000000000000000LL;

std::int64_t count_visit(const std::int64_t *nodes, std::size_t node_count,
                       std::int64_t node, std::size_t depth) noexcept {
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count || depth >= node_count)
        return invalid_result;
    const auto index = static_cast<std::size_t>(node);
    const auto left = nodes[3 * index + 1];
    const auto right = nodes[3 * index + 2];
    if (left < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) || right < -1 ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return invalid_result;
    const auto left_count = left == -1 ? 0 : count_visit(nodes, node_count, left, depth + 1);
    if (left_count == invalid_result) return invalid_result;
    const auto right_count = right == -1 ? 0 : count_visit(nodes, node_count, right, depth + 1);
    if (right_count == invalid_result) return invalid_result;
    return 1 + left_count + right_count;
}
}

extern "C" std::int64_t binary_tree_node_count(const std::int64_t *nodes,
    std::size_t node_count, std::int64_t root_index) noexcept {
    if (nodes == nullptr || node_count == 0 || node_count > max_node_count || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return invalid_result;
    return count_visit(nodes, node_count, root_index, 0);
}
