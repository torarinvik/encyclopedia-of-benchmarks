/* Check whether a root-to-leaf path has the requested sum. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_NODES = 63;

bool path_has_sum(const std::int64_t *input, std::size_t node,
                  std::int64_t sum, std::int64_t target) noexcept
{
    const auto base = 2 + 3 * node;
    sum += input[base];
    const auto left = input[base + 1], right = input[base + 2];
    if (left == -1 && right == -1) return sum == target;
    return (left != -1 && path_has_sum(input, static_cast<std::size_t>(left), sum, target)) ||
           (right != -1 && path_has_sum(input, static_cast<std::size_t>(right), sum, target));
}
}

extern "C" std::int64_t path_sum(const std::int64_t *input, std::size_t length) noexcept
{
    if (length < 2 || input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_NODES)) return -1;
    const auto count = static_cast<std::size_t>(input[1]);
    if (length != 2 + 3 * count) return -1;
    if (count == 0) return 0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto base = 2 + 3 * index;
        if (input[base] < INT32_MIN || input[base] > INT32_MAX) return -1;
        for (std::size_t edge = 1; edge <= 2; ++edge)
            if (input[base + edge] < -1 || input[base + edge] >= static_cast<std::int64_t>(count)) return -1;
    }
    std::array<bool, MAX_NODES> seen{};
    std::array<std::size_t, MAX_NODES> stack{};
    std::size_t top = 1, visited = 0;
    stack[0] = 0;
    while (top > 0) {
        const auto node = stack[--top];
        if (seen[node]) return -1;
        seen[node] = true;
        ++visited;
        const auto base = 2 + 3 * node;
        const auto left = input[base + 1], right = input[base + 2];
        if (left != -1) stack[top++] = static_cast<std::size_t>(left);
        if (right != -1) stack[top++] = static_cast<std::size_t>(right);
    }
    if (visited != count) return -1;
    return path_has_sum(input, 0, 0, input[0]) ? 1 : 0;
}
