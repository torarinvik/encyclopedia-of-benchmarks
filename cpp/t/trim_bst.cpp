// Trim a BST and serialize the retained indexed tree in preorder node-table order.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 100;
constexpr std::int64_t max_value = 10000;

bool valid_bst(const std::int64_t *nodes, std::size_t node_count, std::int64_t root_index)
{
    std::array<std::size_t, max_node_count> parents{};
    for (std::size_t index = 0; index < node_count; ++index) {
        const auto value = nodes[3 * index];
        const auto left = nodes[3 * index + 1], right = nodes[3 * index + 2];
        if (value < 1 || value > max_value || left < -1 || right < -1 ||
            (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
            (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return false;
        if (left >= 0 && ++parents[static_cast<std::size_t>(left)] > 1) return false;
        if (right >= 0 && ++parents[static_cast<std::size_t>(right)] > 1) return false;
    }
    if (parents[static_cast<std::size_t>(root_index)] != 0) return false;
    for (std::size_t index = 0; index < node_count; ++index)
        if (index != static_cast<std::size_t>(root_index) && parents[index] != 1) return false;

    std::array<std::int64_t, max_node_count> stack_node{}, stack_low{}, stack_high{};
    std::array<bool, max_node_count> seen{};
    std::size_t top = 1, visited = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = max_value + 1;
    while (top > 0) {
        --top;
        const auto index = static_cast<std::size_t>(stack_node[top]);
        const auto lower = stack_low[top], upper = stack_high[top];
        if (seen[index]) return false;
        seen[index] = true;
        ++visited;
        const auto value = nodes[3 * index];
        if (value <= lower || value >= upper) return false;
        const auto left = nodes[3 * index + 1], right = nodes[3 * index + 2];
        if (right >= 0) {
            stack_node[top] = right; stack_low[top] = value; stack_high[top++] = upper;
        }
        if (left >= 0) {
            stack_node[top] = left; stack_low[top] = lower; stack_high[top++] = value;
        }
    }
    return visited == node_count;
}

std::int64_t trim_node(const std::int64_t *nodes, std::int64_t node,
                       std::int64_t low, std::int64_t high,
                       std::int64_t *output, std::size_t &output_count)
{
    if (node == -1) return -1;
    const auto index = static_cast<std::size_t>(node);
    const auto value = nodes[3 * index];
    const auto left = nodes[3 * index + 1], right = nodes[3 * index + 2];
    if (value < low) return trim_node(nodes, right, low, high, output, output_count);
    if (value > high) return trim_node(nodes, left, low, high, output, output_count);
    const auto trimmed_index = output_count++;
    const auto offset = 1 + 3 * trimmed_index;
    output[offset] = value;
    output[offset + 1] = output[offset + 2] = -1;
    output[offset + 1] = trim_node(nodes, left, low, high, output, output_count);
    output[offset + 2] = trim_node(nodes, right, low, high, output, output_count);
    return static_cast<std::int64_t>(trimmed_index);
}
}

extern "C" std::int64_t trim_bst(const std::int64_t *nodes, std::size_t node_count,
                                 std::int64_t root_index, std::int64_t low, std::int64_t high,
                                 std::int64_t *output, std::size_t output_capacity)
{
    if (node_count > max_node_count || low < 1 || high > max_value || low > high) return -1;
    if (node_count == 0) {
        if (root_index != -1) return -1;
        if (output == nullptr || output_capacity < 1) return -2;
        output[0] = -1;
        return 1;
    }
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count ||
        !valid_bst(nodes, node_count, root_index)) return -1;
    if (output == nullptr || output_capacity < 1 + 3 * node_count) return -2;
    std::size_t output_count = 0;
    output[0] = trim_node(nodes, root_index, low, high, output, output_count);
    return static_cast<std::int64_t>(1 + 3 * output_count);
}
