/* Count target-sum downward paths, restarting at each node as in the source. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_nodes = 63;

std::int64_t count_from(const std::int64_t *input, std::size_t node, std::int64_t sum,
                        std::int64_t target) noexcept
{
    const auto base = 2 + 3 * node;
    std::int64_t count = sum == target ? 1 : 0;
    const auto left = input[base + 1], right = input[base + 2];
    if (left >= 0) count += count_from(input, static_cast<std::size_t>(left),
        sum + input[2 + 3 * static_cast<std::size_t>(left)], target);
    if (right >= 0) count += count_from(input, static_cast<std::size_t>(right),
        sum + input[2 + 3 * static_cast<std::size_t>(right)], target);
    return count;
}

std::int64_t start_at_each_node(const std::int64_t *input, std::size_t node) noexcept
{
    const auto base = 2 + 3 * node;
    std::int64_t count = count_from(input, node, input[base], input[0]);
    const auto left = input[base + 1], right = input[base + 2];
    if (left >= 0) count += start_at_each_node(input, static_cast<std::size_t>(left));
    if (right >= 0) count += start_at_each_node(input, static_cast<std::size_t>(right));
    return count;
}
}

extern "C" std::int64_t binary_tree_path_sum(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || input[1] < 0 || input[1] > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    std::size_t parents[max_nodes]{};
    for (std::size_t node = 0; node < count; ++node) {
        const auto base = 2 + 3 * node;
        if (input[base] < INT32_MIN || input[base] > INT32_MAX) return -1;
        for (std::size_t side = 1; side <= 2; ++side) {
            const auto child = input[base + side];
            if (child < -1 || child >= static_cast<std::int64_t>(count)) return -1;
            if (child >= 0 && ++parents[static_cast<std::size_t>(child)] > 1) return -1;
        }
    }
    if (parents[0] != 0) return -1;
    for (std::size_t node = 1; node < count; ++node) if (parents[node] != 1) return -1;
    bool seen[max_nodes]{};
    std::size_t stack[max_nodes], top = 0, reached = 0;
    stack[top++] = 0;
    while (top > 0) {
        const auto node = stack[--top];
        if (seen[node]) return -1;
        seen[node] = true; ++reached;
        const auto base = 2 + 3 * node;
        if (input[base + 1] >= 0) stack[top++] = static_cast<std::size_t>(input[base + 1]);
        if (input[base + 2] >= 0) stack[top++] = static_cast<std::size_t>(input[base + 2]);
    }
    if (reached != count) return -1;
    return start_at_each_node(input, 0);
}
