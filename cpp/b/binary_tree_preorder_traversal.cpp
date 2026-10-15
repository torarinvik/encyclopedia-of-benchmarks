/* Iterative-order-compatible tree traversal that writes into caller-owned storage. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 100;

bool visit_preorder(const std::int64_t *nodes, std::size_t node_count, std::int64_t node,
                   std::int64_t *output, std::size_t capacity, std::size_t *used) noexcept
{
    if (node == -1) return true;
    if (node < 0 || static_cast<std::uint64_t>(node) >= node_count) return false;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    const auto left = nodes[3 * index + 1], right = nodes[3 * index + 2];
    if (left < -1 || right < -1 ||
        (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
        (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return false;
    if (*used >= capacity) return false;
    output[(*used)++] = value;
    if (!visit_preorder(nodes, node_count, left, output, capacity, used)) return false;
    return visit_preorder(nodes, node_count, right, output, capacity, used);
}
}

extern "C" std::int64_t binary_tree_preorder_traversal(const std::int64_t *nodes,
    std::size_t node_count, std::int64_t root_index, std::int64_t *output,
    std::size_t output_capacity) noexcept
{
    if (node_count > max_node_count || output_capacity < node_count) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == nullptr || output == nullptr || root_index < 0 ||
        static_cast<std::uint64_t>(root_index) >= node_count) return -1;
    std::size_t used = 0;
    if (!visit_preorder(nodes, node_count, root_index, output, output_capacity, &used) ||
        used != node_count) return -1;
    return static_cast<std::int64_t>(used);
}
