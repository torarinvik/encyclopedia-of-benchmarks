/* Recursively count a finite singly linked chain represented in node order. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_payload = -2147483648LL;
constexpr std::int64_t max_payload = 2147483647LL;

std::int64_t count_recursive(const std::int64_t *nodes, std::size_t remaining) noexcept
{
    if (remaining == 0) return 0;
    if (nodes[0] < min_payload || nodes[0] > max_payload) return -1;
    const auto tail_count = count_recursive(nodes + 1, remaining - 1);
    return tail_count < 0 ? -1 : 1 + tail_count;
}
}

extern "C" std::int64_t count_singly_linked_list_recursion(const std::int64_t *input,
                                                            std::size_t length) noexcept
{
    constexpr std::int64_t max_nodes = 64;
    if (input == nullptr || length < 1 || input[0] < 0 || input[0] > max_nodes) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != count + 1) return -1;
    return count_recursive(input + 1, count);
}
