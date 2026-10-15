/* Preserve the source's full tree traversal while validating the BST input. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 1023;
constexpr std::int64_t max_value = 100000;
}

extern "C" std::int64_t range_sum_bst(const std::int64_t *nodes,
                                       std::size_t node_count,
                                       std::int64_t root_index,
                                       std::int64_t low,
                                       std::int64_t high) noexcept
{
    if (node_count > max_node_count || low < 1 || high > max_value || low > high) return -1;
    if (node_count == 0) return root_index == -1 ? 0 : -1;
    if (nodes == nullptr || root_index < 0 || static_cast<std::uint64_t>(root_index) >= node_count)
        return -1;

    std::int64_t parents[max_node_count]{};
    for (std::size_t index = 0; index < node_count; ++index) {
        const auto value = nodes[3 * index];
        const auto left = nodes[3 * index + 1];
        const auto right = nodes[3 * index + 2];
        if (value < 1 || value > max_value || left < -1 || right < -1 ||
            (left >= 0 && static_cast<std::uint64_t>(left) >= node_count) ||
            (right >= 0 && static_cast<std::uint64_t>(right) >= node_count)) return -1;
        if (left >= 0 && ++parents[static_cast<std::size_t>(left)] > 1) return -1;
        if (right >= 0 && ++parents[static_cast<std::size_t>(right)] > 1) return -1;
    }
    if (parents[static_cast<std::size_t>(root_index)] != 0) return -1;
    for (std::size_t index = 0; index < node_count; ++index)
        if (index != static_cast<std::size_t>(root_index) && parents[index] != 1) return -1;

    std::int64_t stack_node[max_node_count], stack_low[max_node_count], stack_high[max_node_count];
    std::int64_t seen[max_node_count]{};
    std::size_t top = 1, visited = 0;
    stack_node[0] = root_index;
    stack_low[0] = 0;
    stack_high[0] = max_value + 1;
    std::int64_t total = 0;
    while (top != 0) {
        --top;
        const auto index = static_cast<std::size_t>(stack_node[top]);
        const auto lower = stack_low[top], upper = stack_high[top];
        if (seen[index] != 0) return -1;
        seen[index] = 1;
        ++visited;
        const auto value = nodes[3 * index];
        const auto left = nodes[3 * index + 1], right = nodes[3 * index + 2];
        if (value <= lower || value >= upper) return -1;
        if (low <= value && value <= high) total += value;
        if (right >= 0) {
            stack_node[top] = right;
            stack_low[top] = value;
            stack_high[top++] = upper;
        }
        if (left >= 0) {
            stack_node[top] = left;
            stack_low[top] = lower;
            stack_high[top++] = value;
        }
    }
    return visited == node_count ? total : -1;
}
