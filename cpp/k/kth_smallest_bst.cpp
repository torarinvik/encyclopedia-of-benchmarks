/* Inorder DFS decrements k and stops as soon as the requested node is found. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;
constexpr std::int64_t max_value = 10000;
constexpr std::int64_t invalid_tree_result = INT64_MIN;

std::int64_t kth_visit(const std::int64_t *nodes, std::size_t node_count,
                       std::int64_t node, std::int64_t *remaining) noexcept
{
    if (node == -1) return -1;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return invalid_tree_result;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    const auto left = nodes[3 * index + 1], right = nodes[3 * index + 2];
    if (value < 0 || value > max_value || left < -1 || right < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return invalid_tree_result;
    const auto left_result = kth_visit(nodes, node_count, left, remaining);
    if (left_result >= 0 || left_result == invalid_tree_result) return left_result;
    --*remaining;
    if (*remaining == 0) return value;
    return kth_visit(nodes, node_count, right, remaining);
}
}

extern "C" std::int64_t kth_smallest_bst(const std::int64_t *nodes,
                                          std::size_t node_count,
                                          std::int64_t root_index,
                                          std::int64_t k) noexcept
{
    if (node_count == 0 || node_count > max_node_count || nodes == nullptr ||
        root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count ||
        k < 1 || static_cast<std::uint64_t>(k) > node_count) return -1;
    auto remaining = k;
    const auto result = kth_visit(nodes, node_count, root_index, &remaining);
    return result >= 0 ? result : -1;
}
