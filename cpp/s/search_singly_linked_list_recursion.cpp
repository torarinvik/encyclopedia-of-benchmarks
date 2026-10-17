#include <cstddef>
#include <cstdint>
#include <array>

namespace {
constexpr std::size_t max_nodes = 64;
struct Node { std::int32_t value; const Node *next; };
bool search_recursion(const Node *node, std::int32_t key) noexcept {
    return node != nullptr && (node->value == key || search_recursion(node->next, key));
}
}

extern "C" std::int64_t search_singly_linked_list_recursion(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_nodes + 2) return -1;
    const auto count_value = input[0], key_value = input[1];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_nodes) ||
        length != static_cast<std::size_t>(count_value) + 2 || key_value < INT32_MIN || key_value > INT32_MAX) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    std::array<Node, max_nodes> nodes{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[i + 2];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        nodes[i].value = static_cast<std::int32_t>(value);
        nodes[i].next = i + 1 < count ? &nodes[i + 1] : nullptr;
    }
    return search_recursion(count == 0 ? nullptr : nodes.data(), static_cast<std::int32_t>(key_value)) ? 1 : 0;
}
