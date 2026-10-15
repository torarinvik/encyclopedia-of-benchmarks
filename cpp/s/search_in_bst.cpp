/* Follow the unique BST branch until the target node or an empty child. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 5000;
constexpr std::int64_t max_value = 10'000'000;
}

extern "C" std::int64_t search_in_bst(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 3) return -1;
    const auto count_value = input[0];
    const auto root = input[1];
    const auto target = input[2];
    if (count_value < 0 || static_cast<std::uint64_t>(count_value) > max_node_count ||
        length != 3 + 3 * static_cast<std::size_t>(count_value) || target < 1 || target > max_value)
        return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (count == 0) return -1;
    if (root < 0 || static_cast<std::uint64_t>(root) >= count) return -1;
    auto node = root;
    while (node != -1) {
        if (node < 0 || static_cast<std::uint64_t>(node) >= count) return -1;
        const auto offset = 3 + 3 * static_cast<std::size_t>(node);
        const auto value = input[offset];
        const auto left = input[offset + 1], right = input[offset + 2];
        if (value < 1 || value > max_value || left < -1 || right < -1 ||
            (left >= 0 && static_cast<std::uint64_t>(left) >= count) ||
            (right >= 0 && static_cast<std::uint64_t>(right) >= count)) return -1;
        if (value == target) return node;
        node = target < value ? left : right;
    }
    return -1;
}
